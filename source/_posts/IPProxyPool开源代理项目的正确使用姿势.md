---
title: IPProxyPool开源代理项目的正确使用姿势
date: 2017-04-23 11:05:37
tags: [proxy , scrapy]
categories: [scrapy]
---

## 本文主要介绍如何在scrapy项目中接入IPProxyPool项目的代理服务

<!-- more -->

### 添加代理中间件
首先必须先对scrapy的中间件有过了解,这里主要是添加一个中间件,动态获取IPProxyPool提供的代理,指定访问次数阈值后切换新的代理,使得代理池保持最新的状态

```python
class ProxyMiddleware(object):
	def __init__(self):
		self.url = "http://127.0.0.1:8000/?types=0&count=10&country=%E5%9B%BD%E5%86%85"
		self.proxy = eval(requests.get(self.url).content)
		self.counts = 0
	def process_request(self,request,spider):
		#这里作一个计数器,在访问次数超过1000次之后就切换一批(10个)高匿代理,使得代理一直保持最新的状态
		if self.counts < 1000:
			pre_proxy = random.choice(self.proxy)
			request.meta['proxy'] = 'http://{}'.format(str(pre_proxy[0])+":"+str(pre_proxy[1]))
			self.counts += 1
		else:
			#进入到这里的这一次就不设定代理了,直接使用本机ip访问
			self.counts = 0
			self.proxy = eval(requests.get(self.url).content)
```


### 在settings.py中设定
```python
DOWNLOADER_MIDDLEWARES = {
	'TingyunSpider.middlewares.RandomUserAgent': 5,
	#开启动态代理
	'TingyunSpider.middlewares.ProxyMiddleware': 30,
	'scrapy.downloadermiddlewares.httpproxy.HttpProxyMiddleware': 200,
}
```

### 开启IPProxyPool项目后台运行

```python
#clone项目到本地
git clone https://github.com/qiyeboy/IPProxyPool

#安装依赖
pip install requests chardet web.py sqlalchemy gevent psutil lxml

#cd到项目根目录,并后台执行它
nohup python IPProxy.py &
```

### 总结
经过实际使用,所获得的代理在可用性上还是存在问题,会出现很多的4xx错误,后续还会再考虑其他代理方式.


