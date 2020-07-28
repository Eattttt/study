#!/bin/bash
#####################################################################
#   File:       Shell about set your iptables
#   Author:     Lao Mao
#   Time:       2020.06.07
#   Mail:       laomao@jishutaicai.com
#####################################################################
clear
cat << EOF
*********************************************************************
***  |  \/  |  / \  / _ \( )___  / ___|| | | | ____| |   | |      ***
***  | |\/| | / _ \| | | |// __| \___ \| |_| |  _| | |   | |      ***
***  | |  | |/ ___ \ |_| | \__ \  ___) |  _  | |___| |___| |___   ***
***  |_|  |_/_/   \_\___/  |___/ |____/|_| |_|_____|_____|_____|  ***
*********************************************************************
>>  This script is dedicated to the first Exam of the Linux Knowledge
>>  for the Chaitin Network Security Class.  --- by laomao
*********************************************************************
EOF

#--------------------------- 脚本相关函数 ---------------------------#

# 脚本初始菜单
function Script_Initial_Menu () {
    # 菜单提示
    echo -e "\033[31m请选择您需要验证的考试部分：\033[0m"
    echo -e ">>>\033[31m 1. \033[0m系统配置部分"
    echo -e ">>>\033[31m 2. \033[0m服务搭建部分"
    echo -e ">>>\033[31m 3. \033[0m信息采集部分"
    echo -e ">>>\033[31m 4. \033[0m基线检查部分"
    echo ">>> 0. Exit"
    sleep 0.1
    read -p ">>> 你的选择是：" CHOOSE_ID
    case $CHOOSE_ID in
        1)
            Exam_System_Configuration      # 系统配置部分
            echo -e "\033[31m请选择您需要验证的考试部分：\033[0m"
            Script_Initial_Menu            # 选择菜单
        ;;
        2)
            Exam_Service_construction      # 服务搭建部分
            echo -e "\033[31m请选择您需要验证的考试部分：\033[0m"
            Script_Initial_Menu            # 选择菜单
        ;;
        3)
            Exam_Collect_Message           # 信息采集部分
            echo -e "\033[31m请选择您需要验证的考试部分：\033[0m"
            Script_Initial_Menu            # 选择菜单
        ;;
        4)
            Exam_Baseline_Check            # 基线检查部分
            echo -e "\033[31m请选择您需要验证的考试部分：\033[0m"
            Script_Initial_Menu            # 选择菜单
        ;;
        *)
            exit
        ;;
    esac
}
#--------------------------- 考试相关函数 ---------------------------#
# 系统配置部分
function Exam_System_Configuration () {
    
    #    （此处到时候做一个判断，判断网卡信息）
    # 1. 设置系统IP地址，子网掩码，网关，首选DNS，备用DNS
    system_en=`cat /proc/net/dev | awk -F": " '{print $1}' | grep en`
    sed -i "s/BOOTPROTO=dhcp/BOOTPROTO=static/g" /etc/sysconfig/network-scripts/ifcfg-$system_en
    sed -i "s/UUID*/#UUID/g" /etc/sysconfig/network-scripts/ifcfg-$system_en
    sed -i "s/ONBOOT=no/ONBOOT=yes/g" /etc/sysconfig/network-scripts/ifcfg-$system_en
    is_appr=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $1}'`
    if [ "$is_appr" = "IPADDR" ]; then
        # 存在则整行替换
        sed -i '/IPADDR/c\IPADDR=10.1.1.1' /etc/sysconfig/network-scripts/ifcfg-$system_en
    else
        # 不存在则添加一行
        sed -i '/ONBOOT=yes/a\IPADDR=10.1.1.1' /etc/sysconfig/network-scripts/ifcfg-$system_en
    fi
    is_appr=`grep NETMASK /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $1}'`
    if [ "$is_appr" = "NETMASK" ]; then
        # 存在则整行替换
        sed -i '/NETMASK/c\NETMASK=255.255.255.0' /etc/sysconfig/network-scripts/ifcfg-$system_en
    else
        # 不存在则添加一行
        sed -i '/IPADDR=10.1.1.1/a\NETMASK=255.255.255.0' /etc/sysconfig/network-scripts/ifcfg-$system_en
    fi
    is_appr=`grep DNS1 /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $1}'`
    if [ "$is_appr" = "DNS1" ]; then
        # 存在则整行替换
        sed -i '/DNS1/c\DNS1=202.106.0.20' /etc/sysconfig/network-scripts/ifcfg-$system_en
    else
        # 不存在则添加一行
        sed -i '/NETMASK=255.255.255.0/a\DNS1=202.106.0.20' /etc/sysconfig/network-scripts/ifcfg-$system_en
    fi
    is_appr=`grep DNS2 /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $1}'`
    if [ "$is_appr" = "DNS2" ]; then
        # 存在则整行替换
        sed -i '/DNS2/c\DNS2=114.114.114.114' /etc/sysconfig/network-scripts/ifcfg-$system_en
    else
        # 不存在则添加一行
        sed -i '/DNS1=202.106.0.20/a\DNS2=114.114.114.114' /etc/sysconfig/network-scripts/ifcfg-$system_en
    fi
    is_appr=`grep GATEWAY /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $1}'`
    if [ "$is_appr" = "GATEWAY" ]; then
        # 存在则整行替换
        sed -i '/GATEWAY/c\GATEWAY=10.1.1.254' /etc/sysconfig/network-scripts/ifcfg-$system_en
    else
        # 不存在则添加一行
        sed -i '/DNS2=114.114.114.114/a\GATEWAY=10.1.1.254' /etc/sysconfig/network-scripts/ifcfg-$system_en
    fi
    systemctl restart network
    # 2. 关闭selinux，当前按关闭并且永久关闭
    setenforce 0
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
    systemctl stop firewalld
    systemctl disable firewalld
    iptables -F
    # 3. 创建/backup目录，将/etc目录tar包到backup目录下
    cd /root/
    if test ! -d /backup; then
        mkdir /backup
    fi
    tar -zcf /backup/etc_`date +%M`.tar.gz  /etc &> /dev/null
    # 4. 修改hosts文件，解析www.chaitin.com解析到10.1.1.1，www.alibaba.com解析到10.1.1.1。
    sed -i '/::1*/a\10.1.1.1 www.chaitin.com' /etc/hosts
    sed -i '/www.chaitin.com/a\10.1.1.1 www.alibaba.com' /etc/hosts
    # 5. 创建/var/www/html/目录
    if test ! -d /var/www/html/; then
        mkdir -p /var/www/html/
    fi
    # 6. 创建用户chaitin和alibaba，并且制定家目录分别位于/var/www/html/chaitin和/var/www/html/alibaba/，账户使用期限于2020年10月1日到期，并且设置用户密码（密码自拟）。
    useradd -d /var/www/html/chaitin -e 2020-10-01 chaitin
    echo -e "\033[31m更改chaitin用户密码，请输入你为chaitin用户创建的密码：\033[0m"
    passwd chaitin
    useradd -d /var/www/html/alibaba -e 2020-10-01 alibaba
    echo -e "\033[31m更改alibaba用户密码，请输入你为alibaba用户创建的密码：\033[0m"
    passwd alibaba
    # 7. 修改/var/www/html/chaitin和/var/www/html/alibaba的目录权限为755
    chmod -R 755 /var/www/html/chaitin
    chmod -R 755 /var/www/html/alibaba
    # 8. 在/var/www/html/chaitin和/var/www/html/alibaba目录下分别创建网站测试首页。
    # 8.1 测试页面test1.html
    echo "<html>" > /var/www/html/chaitin/index.html
    echo "<h1>Hello, Chaitin!!</h1>" >> /var/www/html/chaitin/index.html
    echo "</html>" >> /var/www/html/chaitin/index.html
    # 8.2 测试页面test2.html
    echo "<html>" > /var/www/html/alibaba/index.html
    echo "<h1>Hello, Alibaba!!</h1>" >> /var/www/html/alibaba/index.html
    echo "</html>" >> /var/www/html/alibaba/index.html
    if [ $? -eq 0 ]; then 
        echo "正在进行系统配置 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 配置成功！! "  
        echo "第一部分完成，请进行验证。"
    else
        echo "正在进行系统配置 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 配置失败！! "  
    fi
}
# 服务搭建部分
function Exam_Service_construction () {
    
    # 1. 设置本地YUM源
    # 1.1 卸载及挂载镜像
    umount /dev/sr0
    mount /dev/sr0 /media
    # 1.2 删除原有的yum源
    rm -rf /etc/yum.repos.d/*
    # 1.3 新建yum源
    echo "[exam]" > /etc/yum.repos.d/exam.repo
    echo "name=exam" >> /etc/yum.repos.d/exam.repo
    echo "baseurl=file:///media/" >> /etc/yum.repos.d/exam.repo
    echo "enable=1" >> /etc/yum.repos.d/exam.repo
    echo "gpgcheck=0" >> /etc/yum.repos.d/exam.repo
    # 1.4 清除无效yum源
    rm -f /var/run/yum.pid
    yum clean all
    # 1.5 刷新yum列表
    yum list
    
    # 2.安装samba服务，共享/backup目录，有alibaba和chaitin账户可以访问，不能写入；root可以访问还可以上传。
    groupadd -g 1500 manager
    gpasswd -M chaitin,alibaba manager
    ## 2.2 安装samba程序
    cd /media/Packages
    #rpm -ivh samba-winbind-modules-4.2.3-10.el7.x86_64.rpm
    #rpm -ivh samba-winbind-4.2.3-10.el7.x86_64.rpm
    #rpm -ivh samba-4.2.3-10.el7.x86_64.rpm
    #rpm -ivh samba-winbind-clients-4.2.3-10.el7.x86_64.rpm
    yum -y install samba*
    ## 2.3 将系统账户添加到samba访问认证库中
    echo -e "\033[31m请为samba服务的root用户设置访问密码：\033[0m"
    pdbedit -a -u root
    echo -e "\033[31m请为samba服务的chaitin用户设置访问密码：\033[0m"
    pdbedit -a -u chaitin
    echo -e "\033[31m请为samba服务的alibaba用户设置访问密码：\033[0m"
    pdbedit -a -u alibaba
    ## 2.4 打开samba主配置文件，进行共享目录声明配置
    #vim /etc/samba/smb.conf
    sed -i '$a[backup]' /etc/samba/smb.conf
    #sed -i '/write list = +staff/a\[backup]' /etc/samba/smb.conf
    sed -i '$a path=/backup' /etc/samba/smb.conf
    sed -i '$a public=no' /etc/samba/smb.conf
    sed -i '$a valid users=root,@manager' /etc/samba/smb.conf
    sed -i '$a write list=root' /etc/samba/smb.conf
    ## 2.5 重启服务
    systemctl start smb.service
    systemctl start nmb.service
    systemctl restart smb.service
    systemctl restart nmb.service

    # 3.编译安装apache服务，添加两个测试站点/var/www/html/chaitin和/var/www/html/alibaba，修改配置文件开启虚拟主机功能，使用基于域名访问两个网站。
    # 3.1 卸载冲突软件
    rpm -e httpd httpd-manual webalizer subversion mod_python mod_ssl mod_perl system-config-httpd php php-cli php-ldap php-common mysql dovecot --nodeps > /dev/null
    # 3.2 解压
    cd /root/
    tar zxf httpd-2.2.17.tar.gz -C /usr/src/
    # 3.3 配置
    cd /usr/src/httpd-2.2.17/
    ./configure --prefix=/usr/local/httpd --enable-so --enable-rewrite --enable-charset-lite --enable-cgi
    # 3.4 编译安装
    make && make install
    # 3.5 优化执行路径
    ln -s /usr/local/httpd/bin/* /usr/local/bin/
    # 3.6 添加系统服务
    cp /usr/local/httpd/bin/apachectl /etc/init.d/httpd
    sed -i '1 a#chkconfig:35 85 15' /etc/init.d/httpd
    sed -i '2 a#description:apache' /etc/init.d/httpd
    sed -i '3 achkconfig --add httpd' /etc/init.d/httpd
    # 3.7 开启服务
    service httpd start
    netstat -anpt | grep 80
    if [ $? -eq 0 ]; then  
        echo "正在开启Apache服务 >>>>>>>>>>>>>>>>>>>>>>>>>> 开启成功！! "  
    else
        echo "正在开启Apache服务 >>>>>>>>>>>>>>>>>>>>>>>>>> 开启失败！! "  
        exit
    fi
    # 3.8 创建两个基于域名的虚拟主机，再客户端分别访问两个网站
    echo > /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "NameVirtualHost 10.1.1.1:80" > /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '<Directory "/var/www/html>"' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "Order Allow,Deny" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "Allow from all" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "</Directory>" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "<VirtualHost www.chaitin.com>" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "  ServerAdmin laomao@jishutaicai.com" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  DocumentRoot "/var/www/html/chaitin"' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "  ServerName www.chaitin.com" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  ErrorLog "logs/chaitin.com-error_log"' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  CustomLog "logs/chaitin.com-access_log" common' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "</VirtualHost>" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "<VirtualHost www.alibaba.com>" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "  ServerAdmin laomao@jishutaicai.com" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  DocumentRoot "/var/www/html/alibaba"' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "  ServerName www.alibaba.com" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  ErrorLog "logs/alibaba.com-error_log"' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo '  CustomLog "logs/alibaba.com-access_log" common' >> /usr/local/httpd/conf/extra/httpd-vhosts.conf
    echo "</VirtualHost>" >> /usr/local/httpd/conf/extra/httpd-vhosts.conf

    # 3.8.2 在httpd的主配置文件中启用虚拟主机，去掉Include前面的注释符
    sed -i "s/#Include conf\/extra\/httpd-vhosts.conf/Include conf\/extra\/httpd-vhosts.conf/g" /usr/local/httpd/conf/httpd.conf
    # 3.9 重启服务
    systemctl restart httpd
    netstat -anpt | grep 80
    if [ $? -eq 0 ]; then  
        echo "正在开启Apache服务 >>>>>>>>>>>>>>>>>>>>>>>>>> 开启成功！! "  
    else
        echo "正在开启Apache服务 >>>>>>>>>>>>>>>>>>>>>>>>>> 开启失败！! "  
        exit
    fi

    # 4.安装vsftpd服务，关闭匿名访问。
    yum -y install vsftpd
    sed -i "s/anonymous_enable=YES/anonymous_enable=NO/g" /etc/vsftpd/vsftpd.conf 
    systemctl start vsftpd
    
    # 5.编译安装mysql服务，创建chaitin数据库，在chaitin数据库中创建user表，user表有3列，ID，names，Tel。
    # 5.1 在光盘安装包目录安装ncurses-devel
    cd /media/Packages
    rpm -ivh ncurses-devel-5.9-13.20130511.el7.x86_64.rpm
    # 5.2 安装cmake工具
    cd /root/
    tar zxf cmake-2.8.6.tar.gz
    cd cmake-2.8.6
    ./configure
    gmake && gmake install

    # 5.3 创建mysql所用的程序账户
    groupadd -g 1501 mysql
    useradd -u 49 -M -s /sbin/nologin -g mysql mysql
    # 5.4 解压缩mysql安装包
    cd /root/
    tar zxf mysql-5.5.22.tar.gz -C /usr/src
    cd /usr/src/mysql-5.5.22/
    # 5.5 配置mysql安装信息
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DSYSCONFDIR=/etc -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all
    # 5.6 编译 && 编译安装mysql
    make && make install
    # 5.7 修改mysql安装目录的归属
    chown -R mysql:mysql /usr/local/mysql
    # 5.8 复制配置文件样板到/etc/my.cnf
    cp /usr/src/mysql-5.5.22/support-files/my-medium.cnf /etc/my.cnf
    # 5.9 初始化数据库信息
    /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
    # 5.10 优化命令执行路径
    ln -s /usr/local/mysql/bin/* /usr/local/bin/
    # 5.11 添加开机启动和系统服务
    cp /usr/src/mysql-5.5.22/support-files/mysql.server /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    chkconfig --add mysqld  # 更新查询系统级服务的运行信息
    systemctl start mysqld
    # 5.12 验证数据库是否开启
    netstat -anpt | grep 3306
    if [ $? -eq 0 ]; then 
        echo "正在开启 MySQL 服务 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 开启成功！! "  
    else
        echo "正在开启 MySQL 服务 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 开启失败！! "  
    fi
    
    # 5.2 创建chaitin数据库，在chaitin数据库中创建user表，user表有3列，ID，names，Tel。
    # 5.3 在chaitin库user表中插入一行信息，01，zhangsan，188183183321
    #mysql -u root -e "create database chaitin;use chaitin; create table user (id int(10), names varchar(20), tel varchar(20));insert into chaitin.user (id, names, tel) values(01, 'zhangsan', "188183183321");"
    mysql -u root << EOF 
    CREATE DATABASE chaitin;
    SHOW DATABASES;
    USE chaitin;
    CREATE TABLE user(ID INT, names VARCHAR(20), Tel VARCHAR(20));
    INSERT INTO chaitin.user ( ID, names, Tel ) VALUES ( 01, "zhangsan", "188183183321" );
EOF

    # 7.安装DHCP服务，分配网段为10.1.1.0/24，地址池10.1.1.100-10.1.1.200，默认网关10.1.1.254，首选DNS为202.106.0.20.
    # 7.1 yum安装dhcp
    yum -y install dhcp*
    echo -e "\033[31m#--------------------------- 默认加载配置 --------------------------#\033[0m"
    echo -e "分配网段为：10.1.1.0/24"
    echo -e "地址池：10.1.1.100-10.1.1.200"
    echo -e "默认网关：10.1.1.254"
    echo -e "默认广播：10.1.1.255"
    echo -e "首选DNS：202.106.0.20"
    echo -e "\033[31m---------------------------------------------------------------------\033[0m"
    # 7.2 修改配置文件
    echo "subnet 10.1.1.0 netmask 255.255.255.0 {" > /etc/dhcp/dhcpd.conf
    echo "range 10.1.1.100 10.1.1.200;" >> /etc/dhcp/dhcpd.conf
    echo "option domain-name-servers 202.106.0.20,114.114.114.114;" >> /etc/dhcp/dhcpd.conf
    echo 'option domain-name "internal.example.org";' >> /etc/dhcp/dhcpd.conf
    echo "option routers 10.1.1.254;" >> /etc/dhcp/dhcpd.conf
    echo "option broadcast-address 10.1.1.255;"  >> /etc/dhcp/dhcpd.conf
    echo "default-lease-time 600;" >> /etc/dhcp/dhcpd.conf
    echo "max-lease-time 7200;" >> /etc/dhcp/dhcpd.conf
    echo "}" >> /etc/dhcp/dhcpd.conf
    systemctl restart httpd
    systemctl start dhcpd
    if [ $? -eq 0 ]; then 
        echo "正在开启 DHCP 服务 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 开启成功！! "  
        echo "第二部分完成，请登录浏览器进行验证。"
    else
        echo "正在开启 DHCP 服务 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> 开启失败！! "  
    fi
}
# 信息收集部分
function Exam_Collect_Message () {

    echo -e "\033[31m#--------------------------- 信息收集部分 --------------------------#\033[0m" > /root/sysinfo
    # 1. 采集系统版本信息，追加到/root/sysinfo文件中
    echo "1. 系统版本信息如下：" >> /root/sysinfo
    cat /etc/redhat-release >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 2. 采集系统IP地址，子网掩码，默认网关，首选DNS，追加到/root/sysinfo文件中
    echo "1. 系统IP地址，子网掩码，默认网关，首选DNS信息如下：" >> /root/sysinfo
    system_en=`cat /proc/net/dev | awk -F": " '{print $1}' | grep en`
    system_ip=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $2}'`
    system_mask=`grep NETMASK /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $2}'`
    system_gate=`grep GATEWAY /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $2}'`
    system_DNS1=`grep DNS1 /etc/sysconfig/network-scripts/ifcfg-$system_en | awk -F"=" '{print $2}'`
    echo "系统IP地址：$system_ip" >> /root/sysinfo
    echo "系统子网掩码：$system_mask" >> /root/sysinfo
    echo "系统默认网关：$system_gate" >> /root/sysinfo
    echo "系统首选DNS：$system_DNS1" >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 3. 采集系统硬盘信息，追加到/root/sysinfo文件中
    echo "3. 系统硬盘信息如下：" >> /root/sysinfo
    df -hT >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 4. 采集系统内存信息，追加到/root/sysinfo文件中
    echo "4. 系统内存信息如下：" >> /root/sysinfo
    cat /proc/meminfo >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 5. 采集系统CPU信息，追加到/root/sysinfo文件中
    echo "5. 系统CPU信息如下：" >> /root/sysinfo
    cat /proc/cpuinfo >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 6. 采集系统中可登录账户，追加到/root/sysinfo文件中
    echo "6. 系统中可登录账户如下：" >> /root/sysinfo
    grep -v "nologin$" /etc/passwd >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 7. 采集系统运行进程的数量，以易读形式追加到/root/sysinfo文件中
    echo "7. 系统运行进程的数量如下：" >> /root/sysinfo
    ps -aux | wc -l >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 8. 采集系统中已安装RPM软件的数量，以易读形式追加到/root/sysinfo文件中
    echo "8. 系统中已安装RPM软件的数量如下：" >> /root/sysinfo
    rpm -qa|wc -l >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo
    # 9. 采集系统当前开放的端口号和所对应的程序名称，追加到/root/sysinfo文件中
    echo "9. 系统当前开放的端口号和所对应的程序名称如下：" >> /root/sysinfo
    netstat -anpt >> /root/sysinfo
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/sysinfo

    echo -e "\033[31m基线检查完毕，请按1选择查看基线检查文档\033[0m"
    read -p ">>> " $CHOOSE_CAT
    if [ $CHOOSE_CAT == 1 ]; then
        cat /root/sysinfo
    else
        return 0
    fi
}
# 基线检查部分
function Exam_Baseline_Check () {

    echo -e "\033[31m#--------------------------- 基线检查部分 --------------------------#\033[0m" > /root/security
    # 1. 检查判断是否存在root以外UID为0的账户。
    echo "1. 检查判断是否存在root以外UID为0的账户：" >> /root/security
    is_0_UIDS=`awk -F: '($3 == 0) { print $1 }' /etc/passwd | wc -l`
    if [ $is_0_UIDS != 1 ]; then
        echo "   × 存在root以外UID为0的账户，不符合安全要求" >> /root/security
    else
        echo "   √ 不存在root以外UID为0的账户，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 2. 检查判断密码最长使用期限是否大于90天超过90天为不合格。
    echo "2. 检查判断密码最长使用期限是否大于90天：" >> /root/security
    is_gt_90=`grep ^PASS_MAX_DAYS /etc/login.defs | awk '{print $2}'`
    if [ $is_gt_90 -gt 90 ]; then
        echo "   × 密码最长使用期限大于90天，不符合安全要求" >> /root/security
    else
        echo "   √ 密码最长使用期限小于90天，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 3. 检查判断是否删除了登录banner信息。
    echo "3. 检查判断是否删除了登录banner信息：" >> /root/security
    if [ -s /etc/issue ]; then
        echo "   × 没有删除登录banner的信息，不符合安全要求" >> /root/security
    else
        echo "   √ 已经删除登录banner的信息，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 4. 检查判断是否响应ICMP协议请求。
    echo "4. 检查判断是否响应ICMP协议请求：" >> /root/security
    is_icmp=`cat /proc/sys/net/ipv4/icmp_echo_ignore_all | awk '{print $1}'`
    if [ $is_icmp -eq 0 ]; then
        echo "   × 仍响应ICMP协议请求，不符合安全要求" >> /root/security
    else
        echo "   √ 未响应ICMP协议请求，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 5. 检查判断是否启用了sshd服务版本2。
    echo "5. 检查判断是否启用了sshd服务版本2：" >> /root/security
    is_sshd_v2=`grep Protocol /etc/ssh/sshd_config | awk '{print $1}'`
    if [ "$is_sshd_v2" = "#Protocol" ]; then
        echo "   × 没有启用sshd服务版本2，不符合安全要求" >> /root/security
    else
        echo "   √ 已经启用sshd服务版本2，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 6. 检查判断sshd服务是否禁止root远程登录系统。
    echo "6. 检查判断sshd服务是否禁止root远程登录系统：" >> /root/security
    is_sshd_remote=`grep ^\#PermitRootLogin /etc/ssh/sshd_config | awk '{print $2}'`
    if [ "$is_sshd_remote" = "yes" ]; then
        echo "   × 没有禁止root远程登录系统，不符合安全要求" >> /root/security
    else
        echo "   √ 已经禁止root远程登录系统，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 7. 检查判断apache服务是否存在浏览器遍历目录的配置。
    echo "7. 检查判断apache服务是否存在浏览器遍历目录的配置：" >> /root/security
    is_apache_dir=`grep "Options Indexes" /usr/local/httpd/conf/httpd.conf | awk '{print $2}'`
    if [ "$is_apache_dir" = "Indexes" ]; then
        echo "   × apache服务存在浏览器遍历目录的配置，不符合安全要求" >> /root/security
    else
        echo "   √ apache服务不存在浏览器遍历目录的配置，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 8. 检查mysql服务是否关闭了网络登录功能。
    echo "8. 检查mysql服务是否关闭了网络登录功能：" >> /root/security
    is_mysql_net=`grep skip-networking /etc/my.cnf | awk '{print $1}'`
    if [ "$is_mysql_net" = "#skip-networking" ]; then
        echo "   × mysql服务没有关闭网络登录功能，不符合安全要求" >> /root/security
    else
        echo "   √ mysql服务已经关闭网络登录功能，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 9. 检查samba是否启用了别名功能。
    echo "9. 检查samba是否启用了别名功能：" >> /root/security
    is_samba_map=`grep -i "username map" /etc/samba/smb.conf | wc -l`
    if [ $is_samba_map -eq 0 ]; then
        echo "   √ samba没有启用别名功能，符合安全要求" >> /root/security
    else
        echo "   × samba启用别名功能，不符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 10. 检查apache是否启用了404错误页面重定向。
    echo "10. 检查apache是否启用了404错误页面重定向：" >> /root/security
    is_apache_404=`grep "ErrorDocument 404 /" /usr/local/httpd/conf/httpd.conf | awk '{print $1}'`
    if [ "$is_apache_404" = "#ErrorDocument" ]; then
        echo "   × apache没有启用404错误页面重定向，不符合安全要求" >> /root/security
    else
        echo "   √ apache已经启用404错误页面重定向，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 11. 检查apache服务是否关闭了版本信息。
    echo "11. 检查apache服务是否关闭了版本信息：" >> /root/security
    is_apache_version=`grep ServerSignature /usr/local/httpd/conf/httpd.conf | awk '{print $2}'`
    if [ "$is_apache_version" = "" ]; then
        echo "   × apache服务没有关闭版本信息，不符合安全要求" >> /root/security
    else
        echo "   √ apache服务已经关闭版本信息，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 12. 检查mysql服务是否禁用了root账户的将数据库导出为文件的权限。
    echo "12. 检查mysql服务是否禁用了root账户的将数据库导出为文件的权限：" >> /root/security
    is_mysql_output=`mysql -u root -e "select File_priv from mysql.user where User='root' and host='localhost';" | awk 'NR==2'`
    if [ "$is_mysql_output" = "Y" ]; then
        echo "   × mysql服务没有禁用了root账户的导出权限，不符合安全要求" >> /root/security
    else
        echo "   √ mysql服务已经禁用了root账户的导出权限，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 13. 检查系统中是否存在配置了sid位的文件或目录。
    echo "13. 检查系统中是否存在配置了sid位的文件或目录：" >> /root/security
    is_sid=`find / -type f \( -perm -04000 -o -perm -02000 \) | xargs -I {} ls -lh {} | wc -l`
    if [ $is_sid -eq 0 ]; then
        echo "   √ 系统中不存在配置了sid位的文件或目录，符合安全要求" >> /root/security
    else
        echo "   × 系统中存在配置了sid位的文件或目录，不符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 14. 检查mysql的配置文件中是否配置了禁止读取本地文件到数据库的功能。
    echo "14. 检查mysql的配置文件中是否配置了禁止读取本地文件到数据库的功能：" >> /root/security
    is_mysql_read=`grep local_infile /etc/my.cnf | awk '{print $1}'`
    if [ "$is_mysql_read" = "" ]; then
        echo "   × mysql没有配置禁止读取本地文件到数据库的功能，不符合安全要求" >> /root/security
    else
        echo "   √ mysql已经配置禁止读取本地文件到数据库的功能，符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security
    # 15. 检查/var/log/messages文件的底层属性是否有加固a属性存在。
    echo "15. 检查/var/log/messages文件的底层属性是否有加固a属性存在：" >> /root/security
    is_lsattr_a=`lsattr /var/log/messages | awk '{print $1}'`
    if [ "$is_lsattr_a" = "-----a----------" ]; then
        echo "   √ /var/log/messages文件的底层属性有加固a属性存在，符合安全要求" >> /root/security
    else
        echo "   × /var/log/messages文件的底层属性无加固a属性存在，不符合安全要求" >> /root/security
    fi
    echo -e "\033[31m---------------------------------------------------------------------\033[0m" >> /root/security

    echo -e "\033[31m基线检查完毕，请按1选择查看基线检查文档\033[0m"
    read -p ">>> " $CHOOSE_CAT
    if [ $CHOOSE_CAT == 1 ]; then
        cat /root/security
    else
        return 0
    fi
}


# 0. 判断安装包是否存在
echo -e "\033[31m#------------------------- 检查所需安装包 --------------------------#\033[0m"
is_cmake=`ls | grep cmake-2.8.6`
if [ "$is_cmake" = "cmake-2.8.6.tar.gz" ]; then
    echo "cmake-2.8.6.tar.gz：ok"
else
    echo "所需cmake-2.8.6.tar.gz安装包不存在，请将安装包放置脚本所在目录，再使用此脚本"
fi
is_httpd=`ls | grep httpd-2.2.17`
if [ "$is_httpd" = "httpd-2.2.17.tar.gz" ]; then
    echo "httpd-2.2.17.tar.gz：ok"
else
    echo "所需httpd-2.2.17.tar.gz安装包不存在，请将安装包放置脚本所在目录，再使用此脚本"
fi
is_mysql=`ls | grep mysql-5.5.22`
if [ "$is_mysql" = "mysql-5.5.22.tar.gz" ]; then
    echo "mysql-5.5.22.tar.gz：ok"
else
    echo "所需mysql-5.5.22.tar.gz安装包不存在，请将安装包放置脚本所在目录，再使用此脚本"
    exit
fi

Script_Initial_Menu
