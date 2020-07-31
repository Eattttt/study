### 安装
1. 解压 -C
2. cd 
3. ./configure --prefix=/usr/loacl/httpd --enable-so --enable-rewrite --enable-charset-lite --enable-cgi
> ./configure --prefix=/usr/loacl/httpd  指定程序安装路径
 --enable-so  支持模块化功能
 --enable-rewrite  支持重写功能
 --enable-charset-lite  支持多字符集，各国文字都有自己的字符集
  --enable-cgi  支持cgi功能

4. 缺少的软件就用yum -y install apr*
5. make && make install
6. /usr/local/httpd/bin/apachectl start
7. tail /usr/local/httpd/logs/access_log
8. vim /usr/local/httpd/conf/httpd.conf
```
开启虚拟主机配置文件
```
9. cp /usr/local/httpd/bin/apachectl /etc/init.d/httpd && service httpd restart
#### 选做
ln -s /usr/local/httpd/bin/* /usr/local/bin/

vim /etc/init.d/httpd
```
#chkconfig:35 85 15
#description:test
```
10. vim /usr/local/httpd/conf/extra/httpd-vhosts.conf
```
<Directory "/var/www/html">
        require all granted
</Directory>
<VirtualHost 202.106.0.10:80>
    DocumentRoot "/var/www/html/alibaba"
    ServerName www.alibaba.com
    ErrorLog "logs/www.alibaba.com-error_log"
    CustomLog "logs/www.alibaba.com-access_log" common
</VirtualHost>
```
### awstats
1. 拷贝到/usr/local/awstats
2. 赋予/usr/local/awstats/tools目录中awstats_*执行权（chmod +x /usr/local/awstats/tools/awstats_*）
3. 执行/usr/local/awstats/tools/awstats_configure.pl
4. 输入httpd.conf路径->y->y->站点标识www.yujie123.com->/n
5. /etc/awstats/awstats.www.yujie123.com.conf文件中LogFile的路径到访问日志文件
6. mkdir /var/lib/awstats
7. vim /usr/local/httpd/conf/httpd.conf内的 /usr/local/awstat/wwwroot的Directory中require all granted 并开启cgid模块
8. 重启httpd服务，并执行/usr/local/awstats/tools/awstats_updateall now
9. 客户机访问地址(http://192.168.3.1/awstats/awstats.pl?config=www.yujie123.com)
10. 在httpd.conf设置白名单` require ip 192.168.3 11.11.11.11`

10.1 黑名单
```
<Directory>
    Options None
    AllowOverride None
<RequireALL>
require all granted
require no ip 192.168.3.10
</RequireALL>
</Directory>
```
10.2 添加用户认证

*创建用户认证文件*
```
# 首次创建.ctpwd需要-c
./htpasswd -c /usr/local/httpd/.ctpwd zhangsan
./htpasswd /usr/local/httpd/.ctpwd lisi
```
######  *httpd.conf*
```
<Directory "/usr/local/awstats/wwwroot">
    Options None
    AllowOverride None
#    require all granted
#    require ip 192.168.3.250

# black list
<RequireAll>
require all granted
require not ip 192.168.3.19
AuthName "JoJo!H!E!L!P!"
AuthType Basic
AuthUserFile /usr/local/httpd/.ctpwd
require valid-user
</RequireAll>

</Directory>
```
###### *httpd-vhosts.conf* 
```
<Directory "/var/www/html/yujie">
<RequireAll>
        require all granted
        AuthName "xxxx"
        AuthType Basic
        AuthUserFile /usr/local/httpd/.ctpwd
        require valid-user
</RequireAll>
</Directory>
```

`重启服务httpd`
