#!/bin/bash

# 一、系统配置部分
# 1.设置系统IP地址为10.1.1.1，子网掩码255.255.255.0，网关10.1.1.254，首选DNS为202.106.0.20，备用DNS设置为114.114.114.114。
IP="10.1.1.1"
MASK="255.255.255.0"
GATEWAY="10.1.1.254"
DNS1="202.106.0.20"
DNS2="114.114.114.114"
WL=$(ifconfig | head -1 | awk -F: '{print $1}')
sed -i "/^ONBOOT/s/no/yes/g" /etc/sysconfig/network-scripts/ifcfg-$WL
sed -i "/^BOOTPROTO/s/dhcp/static/g" /etc/sysconfig/network-scripts/ifcfg-$WL
sed -i "s/^UUID/#&/g" /etc/sysconfig/network-scripts/ifcfg-$WL
echo "GATEWAY=$GATEWAY" >>/etc/sysconfig/network-scripts/ifcfg-$WL
echo "DNS1=$DNS1" >>/etc/sysconfig/network-scripts/ifcfg-$WL
echo "DNS2=$DNS2" >>/etc/sysconfig/network-scripts/ifcfg-$WL
systemctl restart network

# 2.关闭selinux，当前关闭并且永久关闭
setenforce 0
systemctl stop firewalld
iptables -F
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# 3.创建/backup目录，将/etc目录tar包到backup目录下。
mkdir /backup
tar -zcf /backup/bf.tar.gz /etc/

# 4.修改hosts文件，解析www.chaitin.com解析到10.1.1.1，www.alibaba.com解析到10.1.1.1。
echo "10.1.1.1    www.chaitin.com " >>/etc/hosts
echo "10.1.1.1    www.alibaba.com " >>/etc/hosts

# 5.创建/var/www/html/目录
mkdir -p /var/www/html

# 6.创建用户chaitin和alibaba，并且制定家目录分别位于/var/www/html/chaitin和/var/www/html/alibaba/，账户使用期限于2020年10月1日到期，并且设置用户密码（密码自拟）。
useradd -d /var/www/html/chaitin -e 2020-10-01 chaitin
echo 123.com | passwd --stdin chaitin
useradd -d /var/www/html/alibaba -e 2020-10-01 alibaba
echo 123.com | passwd --stdin alibaba

# 7.修改/var/www/html/chaitin和/var/www/html/alibaba的目录权限为755
chmod 755 /var/www/html/chaitin
chmod 755 /var/www/html/alibaba

# 8.在/var/www/html/chaitin和/var/www/html/alibaba目录下分别创建网站测试首页。
echo "<h1>chaiting!!!</h1>" >/var/www/html/chaitin/index.html
echo "<h1>alibaba!!!</h1>" >/var/www/html/alibaba/index.html

# 二、服务搭建部分(注意检查服务是否正确启动)
# 1.设置本地YUM源。

umount /dev/sr0
mount /dev/sr0 /media

rm -rf /etc/yum.repos.d/*
cat <<EOF >/etc/yum.repos.d/cxcyum.repo
[cxcyum]
name=cxcyum
baseurl=file:///media
enable=1
gpgcheck=0
EOF

yum list 
if [ $? -eq 0 ]; then
    echo yum test success!
fi

# 2.安装samba服务，共享/backup目录，有alibaba和chaitin账户可以访问，不能写入；root可以访问还可以上传。

#安装
rpm -ivh /root/samba-winbind-modules-4.2.3-10.el7.x86_64.rpm 
rpm -ivh /root/samba-winbind-4.2.3-10.el7.x86_64.rpm 
rpm -ivh /root/samba-4.2.3-10.el7.x86_64.rpm 
rpm -ivh /root/samba-winbind-clients-4.2.3-10.el7.x86_64.rpm 

#将系统账户添加到samba访问认证库中
pdbedit -a -u chaitin
pdbedit -a -u alibaba
pdbedit -a -u root

#修改samba的主配置文件
cat <<samba >>/etc/samba/smb.conf
[backup]
comment = everyone allow
path = /backup
public = no
read only = yes
valid users = chaitin,alibaba,root
write list = root
samba

#开启服务
systemctl start smb.service
systemctl start nmb.service

# 3.编译安装apache服务，添加两个测试站点/var/www/html/chaitin和/var/www/html/alibaba，修改配置文件开启虚拟主机功能，使用基于域名访问两个网站。

# 卸载原有httpd
rpm -e httpd httpd-manual webalizer subversion mod_python mod_ssl mod_perl system-config-httpd php php-cli php-ldap php-common mysql dovecot --nodeps

#安装依赖环境
yum -y install apr*
yum -y install pcre*

# httpd编译安装
tar -xf /root/httpd-2.4.43.tar -C /usr/src/
cd /usr/src/httpd-2.4.43.tar
./configure \
    --prefix=/usr/local/httpd \
    --enable-so \
    --enable-charset-lite \
    --enable-cgi \
    --enable-rewrite \
    --disable-access
make && make install 

# 修改配置文档
sed -i "/^#ServerName/s/#//g" /usr/local/httpd/conf/httpd.conf
sed -i "/^ServerName/s/www.example.com/www.chaitin.com/g" /usr/local/httpd/conf/httpd.conf

# 优化路径
ln -s /usr/local/httpd/bin/* /usr/local/bin/

#添加系统服务
cp /usr/local/httpd/bin/apachectl /etc/init.d/httpd
sed -i '/#!\/bin\/sh/a\#chkconfig:35 85 15\n#description:apache' /etc/init.d/httpd
chkconfig --add httpd

# 添加虚拟主机
cat <<httpd >>/usr/local/httpd/conf/extra/httpd-vhosts.conf
<VirtualHost 10.1.1.1:80>
    DocumentRoot "/var/www/html/chaitin"
    ServerName www.chaitin.com
    ErrorLog "logs/chaitin.com-error_log"
    CustomLog "logs/chaitin.com-access_log" common
</VirtualHost>
<VirtualHost 10.1.1.1:80>
    DocumentRoot "/var/www/html/alibaba"
    ServerName www.alibaba.com
    ErrorLog "logs/alibaba.com-error_log"
    CustomLog "logs/alibaba.com-access_log" common
</VirtualHost>
<Directory "/var/www/html">
    require all granted
</Directory>
httpd

# 开启vhosts模块
echo "Include conf/extra/httpd-vhosts.conf" >>/usr/local/httpd/conf/httpd.conf

# 开启服务
systemctl start httpd
cd

# 4.安装vsftpd服务，关闭匿名访问。
rpm -ivh /media/Packages/vsftpd-3.0.2-27.el7.x86_64.rpm
sed -i "/^anonymous_enable/s/YES/NO/g" /etc/vsftpd/vsftpd.conf

# 5.编译安装mysql服务，创建chaitin数据库，在chaitin数据库中创建user表，user表有3列，ID，names，Tel。
# 卸载原有mysql
    rpm -e mysql
    rpm -e mysql-server

# 安装ncurses-devel
yum -y install ncurses-devel 

# cmake编译
tar -zxf /root/cmake-2.8.6.tar.gz -C /usr/src/
cd /usr/src/cmake-2.8.6
./configure && gmake && gmake install 

# 创建系统账户
groupadd -g 1500 mysql
useradd -u 49 -M -s /sbin/nologin -g mysql mysql

# mysql编译
tar -zxf /root/mysql-5.5.22.tar.gz -C /usr/src/
cd /usr/src/mysql-5.5.22
rm -rf CMakeCache.txt
cmake \
    -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
    -DSYCONFDIR=/etc/ \
    -DDEFAULT_CHARSET=utf8 \
    -DDEFAULT_COLLATION=utf8_general_ci \
    -DWITH_EXTRA_CHARSETS=all
make & make install 

# 修改目录
chown -R mysql:mysql /usr/local/mysql

# 复制配置文件样板
cp -f /usr/src/mysql-5.5.22/support-files/my-medium.cnf /etc/my.cnf

# 初始化数据库
/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

# 优化命令执行路径
ln -s /usr/local/mysql/bin/* /usr/local/bin/

# 添加开机启动
cp /usr/src/mysql-5.5.22/support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig --add mysqld
systemctl start mysqld

# 创建chaitin数据库
mysql -uroot -e "CREATE DATABASE chaitin;"

#创建user表
mysql -uroot -e "
use chaitin;
create table user(
ID int,
names varchar(20),
Tel int
);"
cd

# 6.在chaitin库user表中插入一行信息，01，zhangsan，188183183321
mysql -uroot --default-character-set=utf8 -e "insert into chaitin.user values(01,zhangsan,188183183321)"

# 7.安装DHCP服务，分配网段为10.1.1.0/24，地址池10.1.1.100-10.1.1.200，默认网关10.1.1.254，首选DNS为202.106.0.20.
conf="/etc/dhcp/dhcpd.conf"
rpm -q dhcp &>/dev/null
if [ $? -ne 0 ]; then
    rpm -ivh /media/Packages/dhcp-4.2.5-79.el7.centos.x86_64.rpm
fi

grep "subnet" $conf &>/dev/null
if [ $? -ne 0 ]; then
    echo "
ddns-update-style none;
ignore client-updates;
default-lease-time 21600;
max-lease-time 43200;
" >$conf
fi

# 安装DHCP服务，分配网段为10.1.1.0/24，地址池10.1.1.100-10.1.1.200，默认网关10.1.1.254，首选DNS为202.106.0.20.

cat <<dhcp >>$conf
subnet 10.1.1.0 netmask 255.255.255.0 {
    range                           10.1.1.100 10.1.1.200;
    option domain-name-servers      202.106.0.20;
    option domain-name              "cxc.com";
    option routers                  10.1.1.254;
    option broadcast-address        10.1.1.255;
    option subnet-mask              255.255.255.0;
    default-lease-time 600;
    max-lease-time 7200;
    
}
dhcp
service dhcpd restart

#三 基本信息采集部分
#建立文件
touch /root/sysinfo

infofile="/root/sysinfo"
network="/etc/sysconfig/network-scripts/ifcfg-"
networkfile=$network$WL
>$infofile
echo "信息采集"  >> $infofile

#采集系统版本信息
osinfo(){
    osversion=$(cat /etc/redhat-release)
    echo "系统版本信息:"  >> $infofile
    echo "$osversion" >> $infofile
    echo "------------------------"  >> $infofile
}

#采集系统IP地址
netinfo(){
     ip=$(egrep -r "IPADDR"  ${networkfile})
     netmask=$(egrep -r "NETMASK"  ${networkfile})
     gatway=$(egrep -r "GATEWAY"  ${networkfile})
     dns=$(egrep -r "DNS"  ${networkfile})
     echo "系统网络信息:"  >> $infofile
    echo "${ip}" >> $infofile
    echo "${netmask}" >> $infofile
    echo "${gatway}" >> $infofile
    echo "${dns}" >> $infofile
    echo "------------------------"  >> $infofile
}

#采集系统硬盘信息
diskinfo(){
     echo "系统磁盘信息:"  >> $infofile
     fdisk  -l   >> $infofile
     echo "------------------------"  >> $infofile
}

#采集系统内存信息
meminfo(){
     echo "系统内存信息:"  >> $infofile
     free  -m  >> $infofile
    echo "------------------------"  >> $infofile
}

#采集系统CPU信息
cpuinfo(){
     echo "系统内存信息:"  >> $infofile
     lscpu  >> $infofile
    echo "------------------------"  >> $infofile
}

#采集系统中可登录账户
loginuser(){
     echo "系统中可登陆账户:"  >> $infofile
    awk '/\/bin\/bash/' /etc/passwd >> $infofile
    echo "------------------------"  >> $infofile

}

#采集系统运行进程的数量
runps(){
     echo "系统运行进程的数量:"  >> $infofile
     psnum=$(ps axu |wc -l)
     echo "进程数量:$psnum"   >> $infofile
    echo "------------------------"  >> $infofile
}

#采集系统中已安装RPM软件的数量，以易读形式追加到
rpminfo(){
   echo "系统中已安装RPM软件的数量:"  >> $infofile
    rpmnum=$(rpm -qa |wc -l)
    echo "rpmnum:$rpmnum" >>$infofile
    echo "------------------------"  >> $infofile

}

#采集系统当前开放的端口号和所对应的程序名称
portpro(){
      echo "系统当前开放的端口号和所对应的程序名称:"  >> $infofile
    netstat -lnutp | awk '/LISTEN/' |  awk '{print $4 "  " $NF}' | sed -r 's#(.*:)([0-9]{1,5})  (.*/)(.*)#port:\2  pro:\4#g'  >> $infofile
}

main(){
    osinfo
    netinfo
    diskinfo
    meminfo
    cpuinfo
    loginuser
    runps
    rpminfo
    portpro
}
main

#四，基线检查

securityfile="/root/security"
> $securityfile

#1.检查判断是否存在root以外UID为0的账户。
CheckUid(){
#查找非root账号UID为0的账号
     echo "1.检查判断是否存在root以外UID为0的账户。" >> $securityfile

    UIDS=`awk -F[:] 'NR!=1{print $3}' /etc/passwd`
    flag=0
    for i in $UIDS
    do
      if [ $i = 0 ];then
         echo "N:存在非root账号的账号UID为0，不符合要求" >> $securityfile
      else
        flag=1
      fi
    done
    if [ $flag = 1 ];then
      echo "Y:不存在非root账号的账号UID为0，符合要求" >> $securityfile
    fi
    echo "----------------------------" >> $securityfile
}

#2.检查判断密码最长使用期限是否大于90天超过90天为不合格。
Passworld(){
    passmax=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v ^# | awk '{print $2}'`

    echo "2.检查判断密码最长使用期限是否大于90天超过90天为不合格。" >>  $securityfile
    if [ $passmax -le 90 -a $passmax -gt 0 ];then
      echo "Y:口令生存周期为${passmax}天，符合要求" >> $securityfile
    else
      echo "N:口令生存周期为${passmax}天，不符合要求,建议设置不大于90天" >> $securityfile
    fi

}

#3.检查判断是否删除了登录banner信息。
delbanner(){
      echo "3.检查判断是否删除了登录banner信息。" >> $securityfile
    size=$(du -sh /etc/issue  | awk  '{print $1}')
    if [ $size -eq 0 ];then
        echo "删除了登录banner信息" >> $securityfile
    else
       echo "没有删除了登录banner信息" >> $securityfile
    fi
    echo "----------------------------" >> $securityfile

}


#4.检查判断是否响应ICMP协议请求。
icmpreply(){
   echo "4.检查判断是否响应ICMP协议请求。" >>  $securityfile
    ip=$( hostname -I | awk '{print $1}')
    ping -c 1 $ip  >/dev/null
    if [ $? -eq 0 ];then
        echo "响应ICMP协议请求"  >>  $securityfile
    else
        echo "没有响应ICMP协议请求"  >>  $securityfile
    fi
   echo "----------------------------" >> $securityfile

}
#5.检查判断是否启用了sshd服务版本2。
checkssh2(){
    echo "5.检查判断是否启用了sshd服务版本2。" >>  $securityfile
    grep '^Protocol 2' /etc/ssh/sshd_config >/dev/null
      if [ $? -eq 0 ];then
        echo "启用了sshd服务版本2"  >>  $securityfile
    else
        echo "没有启用了sshd服务版本2"  >>  $securityfile
    fi
   echo "----------------------------" >> $securityfile
}



#6.检查判断sshd服务是否禁止root远程登录系统。
PermitRootLogin(){
 echo "6.检查判断sshd服务是否禁止root远程登录系统。" >>  $securityfile
RootLogin=`cat /etc/ssh/sshd_config | grep PermitRootLogin | awk '{print $2}'`
if [ "${RootLogin}" == "yes" ];then
    echo "/etc/ssh/sshd_config中PermitRootLogin配置为yes" >>  $securityfile
else [ "${RootLogin}" == "no" ]
    echo "/etc/ssh/sshd_config中PermitRootLogin配置为no" >> $securityfile
fi
   echo "----------------------------" >> $securityfile

}

#7.检查判断apache服务是否存在浏览器遍历目录的配置。
checklist(){
     echo "----------------------------" >> $securityfile
     echo "7.检查判断apache服务是否存在浏览器遍历目录的配置。" >> $securityfile
    egrep -r "Options Indexes FollowSymLinks" /etc/httpd/   >/dev/null
     if [ $? -eq 0 ];then
        echo "存在浏览器遍历目录的配置。"  >> $securityfile
     else
        echo "没有存在浏览器遍历目录的配置。"  >> $securityfile
     fi
        echo "----------------------------" >> $securityfile

}

#8.检查mysql服务是否关闭了网络登录功能。
mysqllogin(){
   echo "8.检查mysql服务是否关闭了网络登录功能。" >>  $securityfile
    ip=$( hostname -I | awk '{print $1}')
    port=3306
     nc -zv $ip 3306 >/dev/null 2>&1
     if [ $? -eq 0 ];then
        echo "关闭了网络登录功能"  >> $securityfile
     else
        echo "没有关闭了网络登录功能"  >> $securityfile
     fi
        echo "----------------------------" >> $securityfile


}


#9.检查samba是否启用了别名功能。
sambaalias(){

    echo "9.检查samba是否启用了别名功能。" >> $securityfile
     egrep -r "map" /etc/samba/smbusers    >/dev/null 2>&1
     if [ $? -eq 0 ];then
        echo "启用了别名功能。"  >> $securityfile
     else
        echo "没有启用了别名功能。"  >> $securityfile
     fi
    echo "----------------------------" >> $securityfile
}

#10.检查apache是否启用了404错误页面重定向。
checkapache404(){
     echo "----------------------------" >> $securityfile
     echo "#10.检查apache是否启用了404错误页面重定向。" >> $securityfile

     egrep -r "^ErrorDocument 404"  /etc/httpd/ >/dev/null
     if [ $? -eq 0 ];then
        echo "启用了404错误页面重定向"  >> $securityfile
     else
        echo "没有启用了404错误页面重定向"  >> $securityfile
     fi

}

#11.检查apache服务是否关闭了版本信息。
servertoken(){
     echo "11.检查apache服务是否关闭了版本信息" >> $securityfile
    egrep -r "ServerTokens Prod" /etc/httpd/* >/dev/null
    egrep -r "ServerSignature off" /etc/httpd/ >/dev/null
      if [ $? -eq 0 ];then
        echo "关闭了版本信息"  >> $securityfile
     else
        echo "没有关闭了版本信息"  >> $securityfile
     fi
     echo "----------------------------" >> $securityfile

}

#12.检查mysql服务是否禁用了root账户的将数据库导出为文件的权限。
checkrootper(){
     echo "12.检查mysql服务是否禁用了root账户的将数据库导出为文件的权限" >> $securityfile
     mysql -uroot -pxxx > /dev/null 2>/tmp/1.txt
     egrep -r "Access" /tmp/1.txt >/dev/null
    if [ $? -eq 0 ];then
        echo "禁用了root账户的将数据库导出为文件的权限。"  >> $securityfile
    else
        echo "没有禁用了root账户的将数据库导出为文件的权限。"  >> $securityfile
    fi
          echo "----------------------------" >> $securityfile

}

#13.检查系统中是否存在配置了sid位的文件或目录。
checksid(){
 echo "13.检查系统中是否存在配置了sid位的文件或目录" >> $securityfile
unauthorizedfile=$(find / \( -perm -04000 -o -perm -02000 \) -type f )
  if [ -n "${unauthorizedfile}" ];then
         flag=1
     else
         flag=0
     fi

 if [ $flag -eq 0 ];then
     echo "返回值为空，符合规范" >> $securityfile
 else [ $flag -eq 1 ]
     echo "返回值不为空，不符合规范" >>  $securityfile
 fi
      echo "----------------------------" >> $securityfile

}

#14.检查mysql的配置文件中是否配置了禁止读取本地文件到数据库的功能。
chekmysqllocal(){
     echo "14.检查mysql的配置文件中是否配置了禁止读取本地文件到数据库的功能" >> $securityfile
     egrep -r "local-infile" /etc/my.cnf >/dev/null 2>&1
        if [ $? -eq 0 ];then
        echo "禁止读取本地文件到数据库的功能"  >> $securityfile
     else
        echo "没有禁止读取本地文件到数据库的功能"  >> $securityfile
     fi
     echo "----------------------------" >> $securityfile

}

#15.检查文件的底层属性是否有加固a属性存在。
Checkmessages(){
         echo "15.检查文件的底层属性是否有加固a属性存在。" >> $securityfile

     lsattr /var/log/messages | awk -F" " '{print $1}' |egrep "a" >/dev/null
     if [ $? -eq 0 ];then
        echo " /var/log/messages 加固a属性存在 " >> $securityfile
      else
       echo " /var/log/messages 加固a属性不存在 " >> $securityfile
     fi
}


main(){
CheckUid
Passworld
delbanner
icmpreply
checkssh2
PermitRootLogin
checklist
mysqllogin
sambaalias
checkapache404
servertoken
checkrootper
checksid
chekmysqllocal
Checkmessages
}
main