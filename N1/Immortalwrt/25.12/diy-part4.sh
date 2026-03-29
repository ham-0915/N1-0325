#!/bin/bash
set -e  # 任何命令失败立即退出，防止静默跳过错误

# 1. 基础配置
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 删除不存在的 video 仓库，避免 apk update 报错
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-fix-apk-video << 'HOOK'
#!/bin/sh
sed -i '/video/d' /etc/apk/repositories.d/distfeeds.list
exit 0
HOOK

# 3. 升级 Golang 到 26.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 4. 彻底清理 feeds 自带的冲突项
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/applications/luci-app-mosdns feeds/packages/net/mosdns
# 清理 feeds 旧版 openlist，防止顶替 openlist2
rm -rf feeds/packages/net/openlist
rm -rf feeds/luci/applications/luci-app-openlist
# adguardhome：只删核心包（用官方feeds版），保留 feeds/luci 里的 luci-app-adguardhome
rm -rf feeds/packages/net/adguardhome
# 清理 feeds 自带的 docker 全家桶，使用 sbwml 25.12 适配版
rm -rf feeds/luci/applications/luci-app-dockerman
rm -rf feeds/luci/applications/luci-app-docker
rm -rf feeds/packages/utils/docker
rm -rf feeds/packages/utils/dockerd
rm -rf feeds/packages/utils/docker-compose
rm -rf feeds/packages/utils/containerd
rm -rf feeds/packages/utils/runc
rm -rf feeds/packages/utils/tini

# 5. 克隆 Passwall 2（不克隆 Passwall 1）
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
rm -rf package/passwall-packages/shadowsocksr-libev
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/passwall2

# 6. 其他插件
git clone https://github.com/ophub/luci-app-amlogic --depth=1 package/amlogic
git clone https://github.com/gdy666/luci-app-lucky.git --depth=1 package/lucky
git clone https://github.com/sbwml/luci-app-mosdns -b v5 --depth=1 package/mosdns
git clone https://github.com/sbwml/luci-app-openlist2 --depth=1 package/openlist2
git clone https://github.com/nikkinikki-org/OpenWrt-nikki --depth=1 package/nikki
git clone https://github.com/vernesong/OpenClash --depth=1 package/openclash
# AdGuardHome 核心包（kenzok8/small）
git clone https://github.com/kenzok8/small.git --depth=1 package/small
mv package/small/adguardhome package/adguardhome
rm -rf package/small
# dockerman：使用 sbwml 的 25.12 适配版
git clone https://github.com/sbwml/luci-app-dockerman -b openwrt-25.12 --depth=1 package/dockerman

# 7. 更新并安装 feeds
./scripts/feeds install -a -f

# 8. 修正 25.12 兼容层的按钮翻译
if [ -f feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm ]; then
    sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
    sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
fi
