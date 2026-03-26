#!/bin/bash

# 修改IP
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
# 修改主机名
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 更新 golang 到 26.x 版本（需在 feeds update 之前替换，否则 index 会用旧版）
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 移除 feeds 自带的与 passwall 冲突的核心库（在 feeds install 前清理，避免安装旧版）
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
# 移除 feeds 自带的过时 luci-app-passwall
rm -rf feeds/luci/applications/luci-app-passwall
# 移除 feeds 自带的 mosdns（避免与 sbwml v5 版本冲突）
rm -rf feeds/luci/applications/luci-app-mosdns feeds/packages/net/mosdns

# 注册标准 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# ============================================================
# 以下所有 git clone 必须在 feeds install -a 之后执行
# 目的：覆盖 feeds 里可能残留的同名旧包，确保用我们指定的版本
# ============================================================

# Passwall 官方包（核心库 + LuCI）
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
git clone https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci

# Amlogic 晶晨宝盒
git clone https://github.com/ophub/luci-app-amlogic --depth=1 package/amlogic

# Lucky DDNS/反向代理
git clone https://github.com/gdy666/luci-app-lucky.git package/lucky

# OpenList 文件列表
git clone https://github.com/sbwml/luci-app-openlist2 package/openlist

# MosDNS v5
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns

# Nikki 代理
git clone https://github.com/nikkinikki-org/OpenWrt-nikki package/nikki

# OpenClash
git clone https://github.com/vernesong/OpenClash package/openclash

# 修正两处错误的翻译
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
