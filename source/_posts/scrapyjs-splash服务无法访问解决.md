---
title: scrapyjs-splash服务无法访问解决
date: 2017-06-28 15:35:32
tags: [scrapy , splash]
categories: [scrapy]
---

## 本文主要介绍splash服务拒绝访问的解决方法

<!-- more -->


### 场景
由于隔了一段时间没回公司，三个月之前的爬虫代码已经有部分失效，其中有的是网站整改，有的则是由<font color="red">于渲染服务的崩溃</font>。这里我们要提的是splash渲染服务失败的解决方案。

### 访问报错
```shell
[scrapy.downloadermiddlewares.retry] DEBUG: Retrying <POST http://192.168.217.41:8050/render.html> (failed 1 times): Connection was refused by other side: 111: Connection refused.
```
我开始以为只是简单的服务崩溃问题，就上服务器看了下是不是splash docker进程被关了，但是服务器上显示正常运行，试着重启服务，发现如下报错:
### 重启报错
```shell
WARNING: IPv4 forwarding is disabled. Networking will not work.
```
应该是谁把通过ipv4访问资源的服务给关闭了，我们需要重启它
### 解决方法
```shell
sudo vi /etc/sysctl.conf

添加代码：net.ipv4.ip_forward=1

重启network服务：sudo systemctl restart network

输入：sysctl net.ipv4.ip_forward

如果显示：net.ipv4.ip_forward = 1  则表示成功
```

最后在浏览器输入：yourserver_ip:8050 ， 即可正常访问splash服务



