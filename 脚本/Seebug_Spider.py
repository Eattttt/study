
# 第一步请求，请求头无cookie值，服务器返回521状态码和加密的js代码，响应头设置了cookie参数__jsluid_s
# 第二步请求，请求头有cookie值，参数为__jsluid_s和js解密后的__jsl_clearance
# 因此最重要的一步是解密第一步521返回的js代码。

import requests
import urllib3
import re
from parsel import Selector
import execjs
import time
urllib3.disable_warnings()

headers = {'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:77.0) Gecko/20100101 Firefox/77.0'}

def get_cookie(info_seesion, info_url, info_proxy):
    for i in range(1):
        try:
            # 得到第一串加密的js代码
            response_data = info_seesion.get(info_url, headers=headers, proxies=info_proxy, verify=False).text
            # time.sleep(30)
            print(response_data)

            # 将js代码封装成函数
            js1 = re.search('<script>(.*)</script>', response_data).group(1).replace('eval(', 'return(')
            js1 = 'function f(){'+js1+'}'
            print(js1)

            # 返回execjs._external_runtime.ExternalRuntime.Context对象
            object = execjs.compile(js1)

            # 执行test函数，得到第二串js代码
            js2 = object.call("f")
            print(js2)

            # 提取生成cookie的函数
            make_cookie = re.search('document.cookie=(.*)\+\';Expires=', js2).group(1)
            print(make_cookie)

            js3 = 'var window=\'\';function f() { cookie='+make_cookie+'; return cookie}'
            # 返回execjs._external_runtime.ExternalRuntime.Context对象
            object= execjs.compile(js3)

            # 执行test函数，得到cookie
            cookie = object.call("f")
            print(">>> cookie 解密成功")
            print(cookie)

            cookie = {cookie.split("=")[0]:cookie.split("=")[1]}
            return cookie

        except:
            print('产生异常')

    print("获取cookie不成功，请稍后再试")


info_session = requests.session()                               # session保存服务器发送过来的原始cookie信息
info_url = "https://www.seebug.org/vuldb/vulnerabilities"       # url信息
info_proxy = {"http":" http://127.0.0.1:7890 "}                 # proxy信息

#for j in range(20):
    #info_url = "https://www.seebug.org/vuldb/vulnerabilities?page=" + str(j)      # 本想做一个页面循环

cookie = get_cookie(info_session, info_url, info_proxy)

response = info_session.get(info_url, cookies=cookie, headers=headers, verify=False)

# 转换Selector
select = Selector(response.text)
vuln_time = select.xpath("//td[@class='text-center datetime hidden-sm hidden-xs']/text()").extract()
vuln_title = select.xpath("//td[@class='vul-title-wrapper']/a/text()").extract()
vuln_old_url = "https://www.seebug.org"
vuln_new_url = select.xpath("//td[@class='vul-title-wrapper']/a/@href").extract()
for i in range(20):
    print("时间：", vuln_time[i], "标题：", vuln_title[i], "链接：", vuln_old_url+vuln_new_url[i])