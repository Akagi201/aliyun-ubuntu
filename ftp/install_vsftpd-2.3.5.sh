#!/bin/bash

ifdpkg=$(cat /proc/version | grep -Ei "ubuntu|debian")

if [ "$ifdpkg" != "" ];then
	dpkg -P vsftpd &> /dev/null
	if [ ! -f vsftpd_2.3.5-3_amd64.deb ];then
		wget http://t-down.oss-cn-hangzhou.aliyuncs.com/vsftpd_2.3.5-3_amd64.deb
	fi
	if cat /etc/shells | grep /sbin/nologin ;then
		echo ""
	else
		echo /sbin/nologin >> /etc/shells
	fi
	dpkg -i vsftpd_2.3.5-3_amd64.deb
	\cp -fR ./ftp/config-ftp/apt_ftp/* /etc/
fi

/etc/init.d/vsftpd start

chown -R www:www /alidata/www

#bug kill: '500 OOPS: vsftpd: refusing to run with writable root inside chroot()'
chmod a-w /alidata/www

MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="9"
while [ "${n:=1}" -le "$LENGTH" ]
do
	PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
	let n+=1
done

echo "www:$PASS" | chpasswd
sed -i s/'ftp_password'/${PASS}/g account.log