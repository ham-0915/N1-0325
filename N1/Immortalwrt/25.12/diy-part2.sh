#!/bin/bash

# 1. 基础配置
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 注入 kiddin9 软件源 (修正语法)
mkdir -p package/base-files/files/etc/opkg
echo "src/gz kiddin9 https://dl.openwrt.ai/releases/25.12/packages/aarch64_cortex-a53/kiddin9" > package/base-files/files/etc/opkg/customfeeds.conf

# 3. 升级 Golang 到 26.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 4. 彻底清理 feeds 自带的冲突项
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/applications/luci-app-mosdns feeds/packages/net/mosdns

# 5. 克隆 Passwall 1 和 Passwall 2
# 注意：它们共用同一个 packages 依赖仓库
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
rm -rf package/passwall-packages/shadowsocksr-libev
git clone https://github.com/Openwrt-Passwall/openwrt-passwall.git package/passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/passwall2

# 其他插件
git clone https://github.com/ophub/luci-app-amlogic --depth=1 package/amlogic
git clone https://github.com/gdy666/luci-app-lucky.git --depth=1 package/lucky
git clone https://github.com/sbwml/luci-app-mosdns -b v5 --depth=1 package/mosdns
git clone https://github.com/nikkinikki-org/OpenWrt-nikki --depth=1 package/nikki
git clone https://github.com/vernesong/OpenClash --depth=1 package/openclash
# git clone https://github.com/kenzok78/luci-app-adguardhome --depth=1 package/adguardhome

# 6. 更新并安装 feeds
# ./scripts/feeds update -a
./scripts/feeds install -a -f

# 7. 修复 SoftEther 权限并针对 feeds 原生包补丁
find feeds/luci/ -name "Makefile" | xargs sed -i 's/+luci-base/+luci-lib-base +luci-compat/g' 2>/dev/null || true
[ -d feeds/luci/applications/luci-app-softethervpn ] && \
find feeds/luci/applications/luci-app-softethervpn -name "*.json" | xargs sed -i 's/"readonly": true/"readonly": false/g' 2>/dev/null || true

# 8. 修正 25.12 兼容层的按钮翻译
if [ -f feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm ]; then
    sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
    sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
fi

