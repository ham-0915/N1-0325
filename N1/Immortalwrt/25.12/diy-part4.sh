#!/bin/bash
set -e

# 1. 清理 feeds install 重建的冲突软链接
rm -rf package/feeds/packages/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf package/feeds/packages/{mosdns,openlist,docker,dockerd,docker-compose,containerd,runc,tini}
rm -rf package/feeds/luci/{luci-app-passwall,luci-app-passwall2,luci-app-mosdns,luci-app-openlist,luci-app-dockerman,luci-app-docker}

# 2. 修正 luci-compat 翻译
if [ -f feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm ]; then
    sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
    sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
fi
