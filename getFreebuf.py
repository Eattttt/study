#coding:utf-8
from requests import *
import re
from bs4 import BeautifulSoup as bs
i=1
while (1):
	if i==2:
		break
	url='https://www.freebuf.com/page/%d' %i
	header={
		'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36',
		'Cookie': '3cb185a485c81b23211eb80b75a406fd=1592266213; PHPSESSID=lshvisnps62n8gj9ir0j117vo1'
	}
	alldata=get(url,headers=header)
	if alldata.status_code != 200:
		i+=1
		continue
	data=alldata.content
	soup=bs(data,'lxml')
	titles=soup.find_all('div',{'class','news-info'})
	contents=soup.select('.news-info dd.text')
	# print len(titles),len(contents)
	for x in range(len(titles)):
		a_title=titles[x].a.get('title')
		a_content=contents[x].get_text().strip()
		a_links=titles[x].a.get('href')
		print a_title
		print "\t"+a_content
		print a_links+"\n"
	i+=1