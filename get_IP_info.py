"""
time: 2020/10/30
author: Chilema
desc: 获取该IP在微步上的信息（地理位置、标签、运营商、RDNS、开放端口数量），而且会自动删除已爬取的IP记录
无论速度多慢40条微步必出滑动验证码
"""
import requests
import re
import time
import random
from bs4 import BeautifulSoup as bs
url_a='https://x.threatbook.cn/nodev4/ip/'
# 读取IP文件位置
ip_fname='./tmp/ip.txt'
def read_lines(filename):
    with open(filename,'r') as f:
        lines=f.readlines()
    return lines
def main():
    all_ip=read_lines(ip_fname)
    for ip in all_ip:
        ip=ip.strip()
        url=url_a+ip
        headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36',
            'Cookie': '',
            'referer': 'https://x.threatbook.cn/nodev4/ip/'+ip
        }
        data=requests.get(url,headers=headers)
        print(ip+'\t'+str(data.status_code))
        soup=bs(data.content,'lxml')
        # print(soup.select('.position'))
        location_x=soup.select('.position > div')[1]
        location_t=location_x.text.replace('\n','').replace(' ','')
        wbtags=soup.find_all('div',{'class','wb-tag'})
        rdns=soup.find_all('div',{'class','item-info col-lg-3 col-md-4 col-sm-6 col-xs-12'})[3].find_all('span',{'class','value'})[0].text
        asn=soup.find_all('div',{'class','item-info col-lg-3 col-md-4 col-sm-6 col-xs-12'})[7].find_all('span',{'class','value'})[0].text
        port=soup.find_all('div',{'class','item-info col-lg-3 col-md-4 col-sm-6 col-xs-12'})[0].find_all('span',{'class','value'})
        fuck_line=ip+'\t'+location_t+'\t'
        for tag in wbtags:
            fuck_line=fuck_line+tag.text.strip()+','
        fuck_line=fuck_line+'\t'+asn+'\t'+port[0].text+'\t'+rdns+'\n'
        with open('ip_local_tag_asn_port_rdns.txt','a') as f_a:
            f_a.write(fuck_line)
        # time.sleep(random.randint(5,10))
        lines=read_lines(ip_fname)
        with open(ip_fname,'w') as f_w:
            for line in lines:
                if ip in line:
                    continue
                f_w.write(line)
        # exit(0)
        time.sleep(10)
if __name__=='__main__':
    main()