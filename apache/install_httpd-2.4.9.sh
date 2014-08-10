#!/bin/bash
rm -rf httpd-2.4.9 apr-1.5.0 apr-util-1.5.3
if [ ! -f httpd-2.4.9.tar.gz ];then
  wget http://t-down.oss-cn-hangzhou.aliyuncs.com/httpd-2.4.9.tar.gz
fi
tar zxvf httpd-2.4.9.tar.gz

if [ ! -f apr-1.5.0.tar.gz ];then
  wget http://oss.aliyuncs.com/aliyunecs/onekey/apache/apr-1.5.0.tar.gz
fi
tar -zxvf apr-1.5.0.tar.gz
cp -rf apr-1.5.0 httpd-2.4.9/srclib/apr

if [ ! -f apr-util-1.5.3.tar.gz ];then
  wget http://oss.aliyuncs.com/aliyunecs/onekey/apache/apr-util-1.5.3.tar.gz
fi
tar -zxvf apr-util-1.5.3.tar.gz
cp -rf apr-util-1.5.3 httpd-2.4.9/srclib/apr-util

cd httpd-2.4.9
./configure --prefix=/alidata/server/httpd \
--with-mpm=prefork \
--enable-so \
--enable-rewrite \
--enable-mods-shared=all \
--enable-nonportable-atomics=yes \
--disable-dav \
--enable-deflate \
--enable-cache \
--enable-disk-cache \
--enable-mem-cache \
--enable-file-cache \
--with-ssl=/usr/local/ssl \
--enable-ssl \
--with-included-apr \
--enable-modules=all  \
--enable-mods-shared=all

CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)
if [ $CPU_NUM -gt 1 ];then
    make -j$CPU_NUM
else
    make
fi
make install
cp support/apachectl /etc/init.d/httpd
chmod u+x /etc/init.d/httpd
cd ..

\cp /alidata/server/httpd/conf/httpd.conf /alidata/server/httpd/conf/httpd.conf.bak

sed -i "s;#LoadModule rewrite_module modules/mod_rewrite.so;LoadModule rewrite_module modules/mod_rewrite.so\nLoadModule php5_module modules/libphp5.so;" /alidata/server/httpd/conf/httpd.conf
sed -i "s#User daemon#User www#" /alidata/server/httpd/conf/httpd.conf
sed -i "s#Group daemon#Group www#" /alidata/server/httpd/conf/httpd.conf
sed -i "s;#ServerName www.example.com:80;ServerName www.example.com:80;" /alidata/server/httpd/conf/httpd.conf
sed -i "s#/alidata/server/httpd/htdocs#/#" /alidata/server/httpd/conf/httpd.conf
#sed -i "s#<Directory />#<Directory \"/alidata/www\">#" /alidata/server/httpd/conf/httpd.conf
sed -i '/<Directory \/>/,+3 d' /alidata/server/httpd/conf/httpd.conf
sed -i "s#Options Indexes FollowSymLinks#Options FollowSymLinks#" /alidata/server/httpd/conf/httpd.conf
#sed -i "s#AllowOverride None#AllowOverride all#" /alidata/server/httpd/conf/httpd.conf
sed -i "s#DirectoryIndex index.html#DirectoryIndex index.html index.htm index.php#" /alidata/server/httpd/conf/httpd.conf
sed -i "s;#Include conf/extra/httpd-mpm.conf;Include conf/extra/httpd-mpm.conf;" /alidata/server/httpd/conf/httpd.conf
sed -i "s;#Include conf/extra/httpd-vhosts.conf;Include conf/extra/httpd-vhosts.conf;" /alidata/server/httpd/conf/httpd.conf

echo "HostnameLookups off" >> /alidata/server/httpd/conf/httpd.conf
echo "AddType application/x-httpd-php .php" >> /alidata/server/httpd/conf/httpd.conf

echo "Include /alidata/server/httpd/conf/vhosts/*.conf" > /alidata/server/httpd/conf/extra/httpd-vhosts.conf


mkdir -p /alidata/server/httpd/conf/vhosts/
cat > /alidata/server/httpd/conf/vhosts/default.conf << END
<VirtualHost *:80>
        DocumentRoot /alidata/www/default
        ServerName localhost
        ServerAlias localhost
        ErrorLog "/alidata/log/httpd/default-error.log"
        CustomLog "/alidata/log/httpd/default.log" common
</VirtualHost>
END

#adjust httpd-mpm.conf
sed -i 's/StartServers             5/StartServers            10/g' /alidata/server/httpd/conf/extra/httpd-mpm.conf
sed -i 's/MinSpareServers          5/MinSpareServers         10/g' /alidata/server/httpd/conf/extra/httpd-mpm.conf
sed -i 's/MaxSpareServers         10/MaxSpareServers         30/g' /alidata/server/httpd/conf/extra/httpd-mpm.conf
sed -i 's/MaxRequestWorkers      250/MaxRequestWorkers      255/g' /alidata/server/httpd/conf/extra/httpd-mpm.conf

/etc/init.d/httpd start