#!/bin/bash
set -e

# 1. 基础配置
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 修复 apk video 仓库
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-fix-apk-video << 'HOOK'
#!/bin/sh
sed -i '/video/d' /etc/apk/repositories.d/distfeeds.list
exit 0
HOOK

# 3. 升级 Golang
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 4. 删除 feeds 源目录里的冲突包（必须在 feeds install 之前）
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf feeds/packages/net/{mosdns,openlist}
rm -rf feeds/packages/utils/{docker,dockerd,docker-compose,containerd,runc,tini}
rm -rf feeds/luci/applications/{luci-app-passwall,luci-app-passwall2,luci-app-mosdns,luci-app-openlist,luci-app-dockerman,luci-app-docker}

# 5. 克隆自定义包
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
rm -rf package/passwall-packages/shadowsocksr-libev
git clone https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/passwall2
git clone https://github.com/ophub/luci-app-amlogic --depth=1 package/amlogic
git clone https://github.com/gdy666/luci-app-lucky.git --depth=1 package/lucky
git clone https://github.com/sbwml/luci-app-mosdns -b v5 --depth=1 package/mosdns
git clone https://github.com/sbwml/luci-app-openlist2 --depth=1 package/openlist2
git clone https://github.com/nikkinikki-org/OpenWrt-nikki --depth=1 package/nikki
git clone https://github.com/vernesong/OpenClash --depth=1 package/openclash
git clone https://github.com/sbwml/luci-app-dockerman -b openwrt-25.12 --depth=1 package/dockerman
