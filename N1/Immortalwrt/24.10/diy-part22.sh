#!/bin/bash
set -e  # 任何命令失败立即退出，防止静默跳过错误

# 1. 基础环境设置 (IP与主机名)
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 强制升级 Golang 1.25 (24.10 编译 Nikki/Sing-box 必须)
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang

# 3. 清理冲突：删除 feeds 中自带的、版本落后的相关插件及其内核，防止编译报错
PKGS="xray-core v2ray-geodata sing-box chinadns-ng dns2socks hysteria ipt2socks microsocks \
naiveproxy shadowsocks-libev shadowsocks-rust shadowsocksr-libev simple-obfs tcping \
trojan-plus tuic-client v2ray-plugin xray-plugin geoview shadow-tls mosdns luci-app-mosdns"
for pkg in $PKGS; do
    rm -rf feeds/packages/net/$pkg
    rm -rf feeds/luci/applications/luci-app-$pkg
done
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall2
rm -rf feeds/luci/applications/luci-app-ssr-plus
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-nikki
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-lucky
rm -rf feeds/luci/applications/luci-app-openlist

  
# 4. 【官方源植入】 - 确保功能最完整、更新最快
# Passwall 官方 (包含核心包和LuCI面板)
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci

# SSR-Plus 官方
git clone https://github.com/fw876/helloworld package/ssr-plus

# OpenClash 官方
git clone https://github.com/vernesong/OpenClash --depth=1 package/luci-app-openclash

# Nikki (Mihomo) 官方
git clone https://github.com/nikkichas/luci-app-nikki package/luci-app-nikki

# MosDNS+openlist2 官方 (sbwml 优化版，最适合 OpenWrt)
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

# Lucky 官方 (大吉)
git clone https://github.com/gdy666/luci-app-lucky package/lucky

# 5. 修正俩处错误的翻译
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
