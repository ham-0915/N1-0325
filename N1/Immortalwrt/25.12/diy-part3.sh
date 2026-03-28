#!/bin/bash

# 1. 基础配置
sed -i 's/192.168.1.1/192.168.123.2/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 2. 注入 kiddin9 软件源
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
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/passwall-packages
# 【修复】删除下载经常失败的 shadowsocksr-libev（老协议，基本无人使用）
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

# 6. 【核心修复】强制适配 25.12 的 UI 渲染
# 用精确匹配（\b 单词边界）避免误替换 luci-base-xxx 类包名
# 同时合并扫描 package/ 和 feeds/luci/，一次处理完毕
find package/ feeds/luci/ -name "Makefile" | \
    xargs grep -l "luci-base" | \
    xargs sed -i \
        -e 's/+luci-base\b/+luci-lib-base +luci-compat/g' \
        -e 's/DEPENDS:=luci-base\b/DEPENDS:=luci-lib-base +luci-compat/g' \
    2>/dev/null || true

# 7. 更新并安装 feeds
# ./scripts/feeds update -a
./scripts/feeds install -a -f

# 8. 修复 SoftEther 权限
[ -d feeds/luci/applications/luci-app-softethervpn ] && \
find feeds/luci/applications/luci-app-softethervpn -name "*.json" | xargs sed -i 's/"readonly": true/"readonly": false/g' 2>/dev/null || true

# 9. 修正 25.12 兼容层的按钮翻译
if [ -f feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm ]; then
    sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
    sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
fi

# ============================================================
# 10. 注入首次启动修复脚本
# ============================================================
mkdir -p files/etc/uci-defaults

# 【修复】Docker 启动问题
# 文件名加前缀 ham- 避免与系统自带脚本冲突
cat > files/etc/uci-defaults/98-ham-fix-docker << 'EOF'
#!/bin/sh
if [ -f /etc/init.d/dockerd ]; then
    chmod +x /etc/init.d/dockerd
    /etc/init.d/dockerd enable 2>/dev/null
fi
exit 0
EOF
chmod +x files/etc/uci-defaults/98-ham-fix-docker

# 【修复】LuCI 登录/无法进入 Web 界面问题
# 延迟15秒后台异步执行，避免系统启动时服务未就绪导致失败
cat > files/etc/uci-defaults/99-ham-fix-ui << 'EOF'
#!/bin/sh
(
    sleep 15
    rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
    /etc/init.d/rpcd restart
    /etc/init.d/uhttpd restart
) &
exit 0
EOF
chmod +x files/etc/uci-defaults/99-ham-fix-ui
