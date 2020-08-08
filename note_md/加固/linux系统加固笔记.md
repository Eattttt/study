1. 设置高风险文件为最小权限，例如passwd,shadown,group, securetty, services, grub.cfg
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group
chmod 600 /etc/securetty
chmod 644 /etc/services
chmod 600 /boot/grub2/grub.cfg

2. 使用sudo命令设置命令执行权，和禁止敏感操作权限，例如运维账户
    zhangsan  ALL = NOPASSWD:ALL,!/bin/bash,!/bin/tcsh,!/bin/csh,!/bin/su,!/bin/passwd,!/bin/gpasswd,!/bin/vi /etc/sudoers,!/bin/vi /etc/sudoers.d/*,!/usr/bin/vim /etc/sudoers,!/usr/bin/vim /etc/sudoers.d/*,!/usr/sbin/visudo,!/usr/bin/sudo -i,!/bin/vi /etc/ssh/*,!/bin/vim /etc/ssh/*,!/bin/chmod,!/bin/rm,!/bin/mv  

3. 检查其他权限过高的文件
    find / -type f   \( -perm -00007 \) -a -ctime -1 | xargs -I {} ls -lh {}
    ctime：属性变更
    mtime：内容修改
    atime：被访问  

4. 修改不必要的账号登录环境，或者删除，检查/etc/passwd登录环境不为/sbin/nologin的  

5. 找到uid为0的账户，删除，awk -F: '($3 == 0) { print $1 }' /etc/passwd

6. 查找是否存在高权限组的账户,检查/etc/group文件

7. 设置密码策略，最长使用90天，密码最短8位，提前7天提醒
    修改文件==/etc/login.defs==
  ```
  PASS_MAX_DAYS	90	最长使用期限
  PASS_MIN_DAYS	0	最短使用期限
  PASS_MIN_LEN	8	密码最小长度
  PASS_WARN_AGE	7	最长期限到期前7天提醒更改密码
  ```

8. 修改密码策略，最少包含一个小写字母，一个大写字母，一个数字，一个字符，4种符号中必须满足3种，最小长度8位。
   修改文件 ==/etc/pam.d/system-auth==

   password requisite  pam_cracklib.so try_first_pass retry=3 dcredit=-1 lcredit=-1 ucredit=-1 ocredit=-1 minclass=3 minlen=8 
   高版本系统可以使用

   ```
   authconfig --passminlen=8 --update		密码最短8位
   authconfig --enablereqlower --update	包含一个小写
   authconfig --enablerequpper --update	包含一个大写
   authconfig --enablereqdigit --update	包含一个数字
   authconfig --enablereqother --update	包含一个字符
   ```

   在文件/etc/security/pwquality.conf

9. 设置强制密码历史/etc/pam.d/system-auth 
   password sufficient pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5
   
10. 设置账户锁定策略防止暴力破解
     auth required pam_tally2.so deny=6 unlock_time=300 even_deny_root root_unlock_time=60
      强制解锁账户的命令pam_tally2  --user  zhangsan  --reset

11. 设置反码，防止新建对象有不必要的权限
    在文件/etc/profile，/etc/csh.login，/etc/csh.cshrc	，/etc/bashrc
    加入umask  027

12. 修改限制文件，减缓被DDOS攻击带来的危害。
    Vim /etc/security/limits.conf
```
*	 soft		core		0
*	 hard		core		0
*	 hard		rss			5000
*  hard		nproc		20
```
这些行的的意思是：“core 0”表示禁止创建core文件；“nproc 20”把最多进程数限制到20；“rss 5000”表示除了root之外，其他用户都最多只能用5M内存。上面这些都只对登录到系统中的用户有效。通过上面这些限制，就能更好地控制系统中的用户对进程、core文件和内存的使用情况。星号“*”表示的是所有登录到系统中的用户。
限制用户jerry将最多允许使用40个进程，每个进程最多打开50个文件，在shell中可创建的最大文件限制为100MB。最多允许两个admin用户同时登陆系统，同事登陆的wheel组用户不能操作五个。
配置如下：
<domain>         <type>  <item>          <value>
jerry             hard    fsize           102400
jerry             hard    nofile           50
jerry             hard    nproc            40
admin             hard    maxlogins        2
@wheel            hard   maxlogins         5

13. 设置更详细的别名，做到日常维护时，更容易发现安全隐患
14. 关闭使用su命令切换root账户
auth    sufficient   /lib/security/pam_rootok.so
加入wheel组的用户可以使用su切换root账户
auth    required    /lib/security/pam_wheel.so group=wheel 
15. 查询拥有sid的文件，去掉sid位
`find / -type f   \( -perm -04000 -o -perm -02000 \) | xargs -I {} ls -lh {}`
`chmod  ugo-s  文件`
16. 为开放目录设置粘滞位。`chmod o+t xxx`
17. 设置日志服务器
日志发送方：修改应用服务器日志配置文件
`vi  /etc/rsyslog.conf`
确认关键日志审计是否存在
```
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
authpriv.*                                  /var/log/secure
```
并添加两行转发日志信息
```
*.info;mail.none;authpriv.none;cron.none       @IP地址
authpriv.*
```
重启服务
`systemctl  restart  rsyslog`
日志接收方，修改==/etc/rsyslog.conf==
开启接收日志功能
```
$ModLoad imudp
$UDPServerRun 514
$template Remote,“/var/log/%$YEAR%-%$MONTH%-%$DAY%/%fromhost-ip%.log”  
```

远程日志路径
:fromhost-ip, !isequal, "127.0.0.1" ?Remote 本地日志不存储远程文件
重启服务
systemctl  restart  rsyslog

18. 设置日志权限
设置日志目录为640权限，设置公共消息日志底层属性为a， /var/log/messages.*   /etc/shadow，/etc/passwd，/etc/group底层属性为i
27. 关闭telnet服务
    修改telnet配置文件
    vi /etc/xinetd.d/telnet
    确认/修改内容为
    disable=yes
28. SSH使用**白名单**允许跳板机访问源
    修改拒绝策略
    vi  /etc/hosts.deny
    加入信息
    ALL:ALL
    修改允许策略
    vi  /etc/hosts.allow
    加入信息
    sshd:来访者IP地址
29. 固化常见的域名解析
    修改/etc/hosts文件
30. 开启syn队列，减轻**syn洪水**攻击的影响
    修改系统控制文件
    vi  /etc/sysctl.conf
    net.ipv4.tcp_syncookies = 1
    配置生效
    sysctl  -p
31. 设置syn的半连接上限，减轻**syn洪水**攻击
    sysctl  -w  net.ipv4.tcp_max_syn_backlog=2048
32. 不做ICMP响应
    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
33. 关闭无源路由转发，防止被**ARP**攻击
    echo 0 > /proc/sys/net/ipv4/ conf/all/accept_source_route
34. 设置FTP服务器访问白名单
    userlist相关选项
35. 设置FTP服务器的上传权限反码
    anon_umask和local_umask相关选项
36. 去掉FTP服务器的banner信息
    ftpd_banner=” Authorized users only. All activity may be monitored and reported.”
37. 保持时间服务器同步时间，
    检查ntpd服务是否开启
38. 查看是否存在远程登录记录文件，
    检查家目录中是否存在.netrc或.rhosts
39. 更新软件补丁，
    确保在克隆主机上测试补丁完全不影响业务服务，才可以在业务服务器使用。
40. 检查是否存在nfs等危险进程
    检查是否存在敏感进程
    ps aux | grep -E "lockd|nfsd|statd|mountd"
    检查关闭NFS相关服务服务
    systemctl list-unit-files | grep nfs 
    systemctl  disable nfs-client.target
41. 检查是否存在业务外启动的不必要服务
    systemctl list-unit-files | grep enable
42. 检查是否存在不需要的软件
    例如rpm -qa | grep -E "^amanda|^chargen|^chargen-udp|^cups|^cups-lpd|^daytime|^daytime-udp|^echo|^echo-udp|^eklogin|^ekrb5-telnet|^finger|^gssftp|^imap|^imaps|^ipop2|^ipop3|^klogin|^krb5-telnet|^kshell|^ktalk|^ntalk|^rexec|^rlogin|^rsh|^rsync|^talk|^tcpmux-server|^telnet|^tftp|^time-dgram|^time-stream|^uucp"
43. 隐藏登录系统时的banner信息
    清空banner文件echo  >  /etc/issue
44. 设置超时注销和history历史记录
    修改/etc/profile 
    vi  /etc/profile
    修改信息
    HISTFILESIZE=50
    HISTSIZE=50
    TMOUT=180
    生效
    source /etc/profile
    44.禁用grup菜单停留时间
    修改grup配置文件
    vi  /boot/grub2/grub.cfg
    修改等时
    set  timeout=0
45. 关闭ctrl+alt+del重启系统的热键
    注释掉/usr/lib/systemd/system/ctrl-alt-del.target文件所有内容