#!/bin/bash

####---- global variables ----begin####
export nginx_version=1.6.0
export httpd_version=2.4.9
export mysql_version=5.5.37
export php_version=5.4.27
export jdk_version=1.7.0
export tomcat_version=7.0.54

export vsftpd_version=2.3.5
export install_ftp_version=0.0.0
####---- global variables ----end####

web=nginx
install_log=/alidata/website-info.log

####---- version selection ----begin####
tmp=1
read -p "Please select the web of nginx/apache, input 1 or 2 : " tmp
if [ "$tmp" == "1" ];then
  web=nginx
elif [ "$tmp" == "2" ];then
  web=apache
fi

tmp=1
isphp_jdk=1
if echo $web |grep "nginx" > /dev/null;then
  read -p "Please select the nginx version of 1.6.0, input 1: " tmp
  if [ "$tmp" == "1" ];then
    nginx_version=1.6.0
  fi
  
  tmp1=1
  read -p "Please select the web of php/tomcat, input 1 or 2: " tmp1
  if [ "$tmp1" == "1" ];then
	 isphp_jdk=1
	 tmp11=1
	 read -p "Please select the php version of 5.4.27, input 1: " tmp11
	 if [ "$tmp11" == "1" ];then
		  php_version=5.4.27
	 fi
  elif [ "$tmp1" == "2" ];then
		isphp_jdk=2
		tmp12=1
		read -p "Please select the jdk version of 1.7.0, input 1: " tmp12
		if [ "$tmp12" == "1" ];then
		  jdk_version=1.7.0
		fi

		tmp13=1
		read -p "Please select the tomcat version of 7.0.54, input 1: " tmp13
		if [ "$tmp13" == "1" ];then
		  tomcat_version=7.0.54
		fi
  else
	   isphp_jdk=1
	   tmp11=1
	   read -p "Please select the php version of 5.4.27, input 1: " tmp11
	   if [ "$tmp11" == "1" ];then
		   php_version=5.4.27
	   fi
	fi
 else
   tmp21=1
   read -p "Please select the apache version of 2.4.9, input 1: " tmp21
   if [ "$tmp21" == "1" ];then
     httpd_version=2.4.9
   fi
   tmp22=1
   read -p "Please select the php version of 5.4.27, input 1: " tmp22
   if [ "$tmp22" == "1" ];then
	  php_version=5.4.27
   fi
fi

tmp=1
read -p "Please select the mysql version of 5.5.37, input 1:" tmp
if [ "$tmp" == "1" ];then
  mysql_version=5.5.37
fi

tmp=1
read -p "Please select the ftp version of 2.3.5, input 1: " tmp
if [ "$tmp" == "1" ];then
  vsftpd_version=2.3.5
fi

echo ""
echo "You select the version :"
echo "web    : $web"
if echo $web |grep "nginx" > /dev/null;then
  echo "nginx : $nginx_version"
  if [ $isphp_jdk == "1" ];then
	echo "php : $php_version"
  elif [ $isphp_jdk == "2" ];then
	echo "jdk : $jdk_version"
	echo "tomcat : $tomcat_version"	
  fi
else
  echo "apache : $httpd_version"
  echo "php    : $php_version"
fi
echo "mysql  : $mysql_version"
echo "vsftpd : $vsftpd_version"

read -p "Enter the y or Y to continue:" isY
if [ "${isY}" != "y" ] && [ "${isY}" != "Y" ];then
   exit 1
fi
####---- version selection ----end####

####---- Clean up the environment ----begin####
echo "will be installed, wait ..."
./uninstall.sh in &> /dev/null
####---- Clean up the environment ----end####

if echo $web|grep "nginx" > /dev/null;then
web_dir=nginx-${nginx_version}
else
web_dir=httpd-${httpd_version}
fi

php_dir=php-${php_version}

if [ `uname -m` == "x86_64" ];then
machine=x86_64
else
machine=i686
fi

####---- global variables ----begin####
export web
export isphp_jdk
export web_dir
export php_dir
export tomcat_dir=tomcat-${tomcat_version}
export java_dir=java-${jdk_version}
export mysql_dir=mysql-${mysql_version}
####---- global variables ----end####

ifubuntu=$(cat /proc/version | grep ubuntu)

####---- install dependencies ----begin####
\cp /etc/rc.local /etc/rc.local.bak

if [ "$ifubuntu" != "" ];then
  apt-get -y update
  \mv /etc/apache2 /etc/apache2.bak &> /dev/null
  \mv /etc/nginx /etc/nginx.bak &> /dev/null
  \mv /etc/php5 /etc/php5.bak &> /dev/null
  \mv /etc/mysql /etc/mysql.bak &> /dev/null
  apt-get -y autoremove apache2 nginx php5 mysql-server &> /dev/null
  apt-get -y install unzip build-essential libncurses5-dev libfreetype6-dev libxml2-dev libssl-dev libcurl4-openssl-dev libjpeg62-dev libpng12-dev libfreetype6-dev libsasl2-dev libpcre3-dev autoconf libperl-dev libtool libaio*
  iptables -F
else
  echo "error !! Your system is not Ubuntu!"
  exit 0	
fi
####---- install dependencies ----end####

####---- openssl update---begin####
./env/update_openssl.sh
####---- openssl update---end####

####---- install software ----begin####
rm -f tmp.log
echo tmp.log

./env/install_set_ulimit.sh

./env/install_dir.sh
echo "---------- make dir ok ----------" >> tmp.log

if [ $isphp_jdk == "1" ];then
	./env/install_env_php.sh
elif [ $isphp_jdk == "2" ];then
	./env/install_env_tomcat.sh
fi
echo "---------- env ok ----------" >> tmp.log

./mysql/install_${mysql_dir}.sh
echo "---------- ${mysql_dir} ok ----------" >> tmp.log

mkdir -p /alidata/www/default
if echo $web |grep "nginx" > /dev/null;then
	if [ $isphp_jdk == "1" ];then
		./nginx/install_nginx+php-${nginx_version}.sh
		echo "---------- ${web_dir} ok ----------" >> tmp.log
		./php/install_nginx_php-${php_version}.sh
		echo "---------- ${php_dir} ok ----------" >> tmp.log
		cp ./res/index-nginx.html /alidata/www/default/index.html
	elif [ $isphp_jdk == "2" ];then
		./nginx/install_nginx+tomcat-${nginx_version}.sh
		echo "---------- ${web_dir} ok ----------" >> tmp.log
		./jdk/install_jdk-${jdk_version}.sh
		./tomcat/install_tomcat-${tomcat_version}.sh
		echo "---------- ${java_dir} ok ----------" >> tmp.log
		echo "---------- ${tomcat_dir} ok ----------" >> tmp.log
		rm -rf /alidata/www/default
		ln -s /alidata/server/tomcat7/webapps/ROOT/ /alidata/www/default
	fi
else
	./apache/install_httpd-${httpd_version}.sh
	echo "---------- ${web_dir} ok ----------" >> tmp.log
	./php/install_httpd_php-${php_version}.sh
	echo "---------- ${php_dir} ok ----------" >> tmp.log
	cp ./res/index-apache.html /alidata/www/default/index.html
fi

if [ $isphp_jdk != "2" ];then 
	./php/install_php_extension.sh
	echo "---------- php extension ok ----------" >> tmp.log
fi

./ftp/install_vsftpd-${vsftpd_version}.sh
echo "---------- vsftpd-$vsftpd_version  ok ----------" >> tmp.log

####---- install default http ----begin####
if [ $isphp_jdk == "1" ];then
cat > /alidata/www/default/info.php << EOF
<?php
phpinfo();
?>
EOF
elif [ $isphp_jdk == "2" ];then
	echo ""
fi
chown www:www -R /alidata/www/
####---- install default http ----end####

\cp ./res/initPasswd.sh /alidata/init/
chmod 755 /alidata/init/initPasswd.sh
echo "---------- web init ok ----------" >> tmp.log
####---- install software ----end####

####---- Start command is written to the rc.local ----begin####
if ! cat /etc/rc.local | grep "/etc/init.d/mysqld" > /dev/null;then 
    echo "/etc/init.d/mysqld start" >> /etc/rc.local
fi
if echo $web|grep "nginx" > /dev/null;then
  if ! cat /etc/rc.local | grep "/etc/init.d/nginx" > /dev/null;then 
     echo "/etc/init.d/nginx start" >> /etc/rc.local
  fi
  if [ $isphp_jdk == "1" ];then
	 if ! cat /etc/rc.local |grep "/etc/init.d/php-fpm" > /dev/null;then
		echo "/etc/init.d/php-fpm start" >> /etc/rc.local
	 fi
  elif [ $isphp_jdk == "2" ];then
	 if ! cat /etc/rc.local |grep "/etc/init.d/tomcat7" > /dev/null;then
		echo "/etc/init.d/tomcat7 start" >> /etc/rc.local
	 fi
  fi
else
  if ! cat /etc/rc.local | grep "/etc/init.d/httpd" > /dev/null;then 
     echo "/etc/init.d/httpd start" >> /etc/rc.local
  fi
fi
if ! cat /etc/rc.local | grep "/etc/init.d/vsftpd" > /dev/null;then 
    echo "/etc/init.d/vsftpd start" >> /etc/rc.local
fi
if ! cat /etc/rc.local | grep "/alidata/init/initPasswd.sh" > /dev/null;then 
    echo "/alidata/init/initPasswd.sh" >> /etc/rc.local
fi
####---- Start command is written to the rc.local ----end####

if [ "$ifubuntu" != "" ];then
	mkdir -p /var/lock
	sed -i 's#exit 0#touch /var/lock/local#' /etc/rc.local
else
	mkdir -p /var/lock/subsys/
fi

####---- mysql password initialization ----begin####
echo "---------- rc init ok ----------" >> tmp.log
TMP_PASS=$(date | md5sum |head -c 10)
/alidata/server/mysql/bin/mysqladmin -u root password "$TMP_PASS"
sed -i s/'mysql_password'/${TMP_PASS}/g account.log
echo "---------- mysql init ok ----------" >> tmp.log
####---- mysql password initialization ----end####


####---- Environment variable settings ----begin####
\cp /etc/profile /etc/profile.bak
if echo $web|grep "nginx" > /dev/null;then
  if [ $isphp_jdk == "1" ];then
	echo 'export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/nginx/sbin:/alidata/server/php/sbin:/alidata/server/php/bin' >> /etc/profile
	export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/nginx/sbin:/alidata/server/php/sbin:/alidata/server/php/bin
  elif [ $isphp_jdk == "2" ];then
	echo 'export JAVA_HOME=/alidata/server/java' >> /etc/profile
	echo 'export JRE_HOME=/alidata/server/java/jre' >> /etc/profile
	echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH' >> /etc/profile
	echo 'export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/nginx/sbin:$JAVA_HOME/bin' >> /etc/profile
	export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/nginx/sbin:/alidata/server/php/sbin:/alidata/server/php/bin:$JAVA_HOME/bin
  fi
else
  echo 'export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/httpd/bin:/alidata/server/php/sbin:/alidata/server/php/bin' >> /etc/profile
  export PATH=$PATH:/alidata/server/mysql/bin:/alidata/server/httpd/bin:/alidata/server/php/sbin:/alidata/server/php/bin
fi
####---- Environment variable settings ----end####

####---- restart ----begin####
/etc/init.d/php-fpm restart &> /dev/null
/etc/init.d/nginx restart &> /dev/null
/etc/init.d/httpd restart &> /dev/null
/etc/init.d/httpd start &> /dev/null
/etc/init.d/vsftpd restart &> /dev/null
/etc/init.d/tomcat7 restart &> /dev/null
####---- restart ----end####

####---- log ----begin####
\cp tmp.log $install_log
cat $install_log
\cp -a account.log /alidata/
####---- log ----end####
bash