#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
#sed -i "s|\(src-git luci\).*|\1 https://github.com/coolsnowwolf/luci.git;openwrt-23.05|g" feeds.conf.default
sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default
./scripts/feeds update -a 
rm -rf feeds/smpackage/{base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd*,miniupnpd-iptables,wireless-regdb}
#rm -rf feeds/smpackage/{*openclash,*homeproxy,*ikoolproxy}
rm -rf feeds/luci/applications/{luci-app-bypass,luci-app-homeproxy,luci-app-mosdns,luci-app-passwall*,luci-app-ssr-plus}
./scripts/feeds install -a  


CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/192.168.250.1/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='chuhaiwuyou'/g" $CFG_FILE
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=chuhaiwuyou/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")


#修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-kucat/g' ./feeds/luci/collections/luci/Makefile
echo "CONFIG_PACKAGE_luci-theme-kucat=y" >> ./.config


#WIFI驱动
echo "CONFIG_PACKAGE_kmod-ath11k=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-ath11k-ahb=y" >> ./.config
echo "CONFIG_PACKAGE_kmod-ath11k-pci=y" >> ./.config
echo "CONFIG_PACKAGE_ath11k-firmware-ipq6018=y" >> ./.config
echo "CONFIG_PACKAGE_ath11k-firmware-qcn9074=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> ./.config

#预置OpenClash内核和数据
cd ./feeds/smpackage
if [ -d *"openclash"* ]; then
	CORE_VER="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/core_version"
	CORE_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "amd64" || echo "arm64")
	CORE_TUN_VER=$(curl -sL $CORE_VER | sed -n "2{s/\r$//;p;q}")

	CORE_DEV="https://github.com/vernesong/OpenClash/raw/core/dev/dev/clash-linux-$CORE_TYPE.tar.gz"
	CORE_MATE="https://github.com/vernesong/OpenClash/raw/core/dev/meta/clash-linux-$CORE_TYPE.tar.gz"
	CORE_TUN="https://github.com/vernesong/OpenClash/raw/core/dev/premium/clash-linux-$CORE_TYPE-$CORE_TUN_VER.gz"

	GEO_MMDB="https://github.com/alecthw/mmdb_china_ip_list/raw/release/lite/Country.mmdb"
	GEO_SITE="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat"
	GEO_IP="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat"

	cd ./luci-app-openclash/root/etc/openclash/

	#curl -sL -o Country.mmdb $GEO_MMDB && echo "Country.mmdb done!"
	#curl -sL -o GeoSite.dat $GEO_SITE && echo "GeoSite.dat done!"
	curl -sL -o GeoIP.dat $GEO_IP && echo "GeoIP.dat done!"

	mkdir ./core/ && cd ./core/

	curl -sL -o meta.tar.gz $CORE_MATE && tar -zxf meta.tar.gz && mv -f clash clash_meta && echo "meta done!"
	#curl -sL -o tun.gz $CORE_TUN && gzip -d tun.gz && mv -f tun clash_tun && echo "tun done!"
	#curl -sL -o dev.tar.gz $CORE_DEV && tar -zxf dev.tar.gz && echo "dev done!"

	chmod +x ./* && rm -rf ./*.gz

	cd $PKG_PATCH && echo "openclash date has been updated!"
fi
