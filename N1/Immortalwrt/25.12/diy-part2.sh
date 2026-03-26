#!/bin/bash

# 1. 修改默认IP和主机名
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 升级 Golang 以支持最新版插件编译
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 3. 移除可能冲突的旧包
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-mosdns feeds/packages/net/mosdns

# 4. 克隆第三方插件 (在 feeds install 之前)
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages --depth=1 package/passwall-packages
git clone https://github.com/Openwrt-Passwall/openwrt-passwall --depth=1 package/passwall-luci
git clone https://github.com/ophub/luci-app-amlogic --depth=1 package/amlogic
git clone https://github.com/gdy666/luci-app-lucky.git --depth=1 package/lucky
git clone https://github.com/sbwml/luci-app-openlist2 --depth=1 package/openlist
git clone https://github.com/sbwml/luci-app-mosdns -b v5 --depth=1 package/mosdns
git clone https://github.com/nikkinikki-org/OpenWrt-nikki --depth=1 package/nikki
git clone https://github.com/vernesong/OpenClash --depth=1 package/openclash

# 5. 【核心修复】将插件依赖从 luci-base 强制指向 25.12 存在的包
# 批量修改 Makefile 中的依赖项
find package/ -name "Makefile" | xargs sed -i 's/+luci-base/+luci-lib-base +luci-compat/g'
find package/ -name "Makefile" | xargs sed -i 's/DEPENDS:=luci-base/DEPENDS:=luci-lib-base +luci-compat/g'

# 6. 更新并安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 7. 修正翻译显示
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
