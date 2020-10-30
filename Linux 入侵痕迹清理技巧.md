**01、清除history历史命令记录**

**第一种方式：**

（1）编辑history记录文件，删除部分不想被保存的历史命令。

```
vim ~/.bash_history
```

（2）清除当前用户的history命令记录

```
history -c
```

**第二种方式：**

（1）利用vim特性删除历史命令

```
#使用vim打开一个文件vi test.txt
# 设置vim不记录命令，Vim会将命令历史记录，保存在viminfo文件中。:set history=0# 用vim的分屏功能打开命令记录文件.bash_history，编辑文件删除历史操作命令vsp ~/.bash_history# 清除保存.bash_history文件即可。
```

（2）在vim中执行自己不想让别人看到的命令

```
:set history=0:!command
```

**第三种方式：**

通过修改配置文件/etc/profile，使系统不再保存命令记录。

```
HISTSIZE=0
```

**第四种方式：**

登录后执行下面命令,不记录历史命令(.bash_history)

```
unset HISTORY HISTFILE HISTSAVE HISTZONE HISTORY HISTLOG; export HISTFILE=/dev/null; export HISTSIZE=0; export HISTFILESIZE=0
```

**02、清除系统日志痕迹**

Linux 系统存在多种日志文件，来记录系统运行过程中产生的日志。

```
/var/log/btmp   记录所有登录失败信息，使用lastb命令查看/var/log/lastlog 记录系统中所有用户最后一次登录时间的日志，使用lastlog命令查看/var/log/wtmp    记录所有用户的登录、注销信息，使用last命令查看/var/log/utmp    记录当前已经登录的用户信息，使用w,who,users等命令查看/var/log/secure   记录与安全相关的日志信息/var/log/message  记录系统启动后的信息和错误日志
```

**第一种方式：清空日志文件**

清除登录系统失败的记录：

```
[root@centos]# echo > /var/log/btmp [root@centos]# lastb             //查询不到登录失败信息
```

清除登录系统成功的记录：

```
[root@centos]# echo > /var/log/wtmp  [root@centos]# last              //查询不到登录成功的信息
```

清除相关日志信息：

```
清除用户最后一次登录时间：echo > /var/log/lastlog          #lastlog命令清除当前登录用户的信息：echo >   /var/log/utmp             #使用w,who,users等命令清除安全日志记录：cat /dev/null >  /var/log/secure清除系统日志记录：cat /dev/null >  /var/log/message
```

**第二种方式：删除/替换部分日志**

日志文件全部被清空，太容易被管理员察觉了，如果只是删除或替换部分关键日志信息，那么就可以完美隐藏攻击痕迹。

```
# 删除所有匹配到字符串的行,比如以当天日期或者自己的登录ipsed  -i '/自己的ip/'d  /var/log/messages
# 全局替换登录IP地址：sed -i 's/192.168.166.85/192.168.1.1/g' secure
```

**03、清除web入侵痕迹**

**第一种方式：**直接替换日志ip地址

```
sed -i 's/192.168.166.85/192.168.1.1/g' access.log
```

**第二种方式：**清除部分相关日志

```
# 使用grep -v来把我们的相关信息删除,cat /var/log/nginx/access.log | grep -v evil.php > tmp.log
# 把修改过的日志覆盖到原日志文件cat tmp.log > /var/log/nginx/access.log/
```

**04、文件安全删除工具**

**（1）shred命令**

实现安全的从硬盘上擦除数据，默认覆盖3次，通过 -n指定数据覆盖次数。

```
[root@centos]# shred -f -u -z -v -n 8 1.txt shred: 1.txt: pass 1/9 (random)...shred: 1.txt: pass 2/9 (ffffff)...shred: 1.txt: pass 3/9 (aaaaaa)...shred: 1.txt: pass 4/9 (random)...shred: 1.txt: pass 5/9 (000000)...shred: 1.txt: pass 6/9 (random)...shred: 1.txt: pass 7/9 (555555)...shred: 1.txt: pass 8/9 (random)...shred: 1.txt: pass 9/9 (000000)...shred: 1.txt: removingshred: 1.txt: renamed to 00000shred: 00000: renamed to 0000shred: 0000: renamed to 000shred: 000: renamed to 00shred: 00: renamed to 0shred: 1.txt: removed
```

**（2）dd命令**

可用于安全地清除硬盘或者分区的内容。

```
dd if=/dev/zero of=要删除的文件 bs=大小 count=写入的次数
```

**（3）wipe**

Wipe 使用特殊的模式来重复地写文件，从磁性介质中安全擦除文件。

```
wipe filename
```

**（4）Secure-Delete**

Secure-Delete 是一组工具集合，提供srm、smem、sfill、sswap，4个安全删除文件的命令行工具。

```
srm filenamesfill filenamesswap /dev/sda1smem
```

**05、隐藏远程SSH登陆记录**

隐身登录系统，不会被w、who、last等指令检测到。

```
ssh -T root@192.168.0.1 /bin/bash -i
```

不记录ssh公钥在本地.ssh目录中

```
ssh -o UserKnownHostsFile=/dev/null -T user@host /bin/bash –i
```