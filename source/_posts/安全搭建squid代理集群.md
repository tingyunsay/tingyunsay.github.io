---
title: 安全搭建squid代理集群
date: 2019-01-14 19:58:17
tags: [squid代理, 代理集群, 安全]
categories: [spider]
---
## 本文介绍如何安全地搭建需要验证的 squid 代理集群
<!-- more -->

### 背景

　　之前由于长期有一些抓取相关的需求，博主购买了一些云平台的低配机器，在上面配置了 squid，开放了代理端口，然后自己在本地也维护了一个 squid 服务，专门用来连接云服务器的代理。但是就是最近发现连接的代理总是发现大量超时，登录上服务器查看，连 ls/cd 等命令都会卡，nload 了一下，发现带宽全部被打满了，之后就查看了下 squid 的日志，发现已经好几个 G 了，才发现原来是这个东西在搞鬼。检查了 squid 的日志，里面的 ip 有各个地区的，目标也是各种各样，想应该是被哪个代理商扫描到了，直接被用来使用了，开始修改吧

### 具体操作

#### 基本架构

![图一](/安全搭建squid代理集群/1.png)

　　我们只需要维护的本地的 squid.conf 文件即可

#### (代理) 云服务器设定认证账号

　　由于所使用的云服务器都是 centos 的，所以这里只用到了 yum 相关包
```python
#安装squid
yum install squid

#这是apache的一个验证工具
yum install httpd-tools

#openssl
yum install openssl

#输入登录账号密码
htpasswd -c /etc/squid/passwd username
```
#### 配置 squid

　　<font color="red">**注意**</font> 和通常配置不一样的是，我们这回配置的是需要账号密码验证的
```python
#首先要将如下两句都注释掉
#http_access deny all
#http_access allow all
```
　　<font color="red">**不注释掉这两行的话任何配置都无法生效**</font>

　　然后在末尾添加如下部分
```python
auth_param basic program /usr/lib64/squid/basic_ncsa_auth /etc/squid/passwd     #验证密码的程序,和使用的密码字典
auth_param basic children 5           #认证程序的进程数,根据机器配置和请求量设定
acl auth_user proxy_auth REQUIRED     #认证用户需要密码
http_access allow auth_user           #允许上面acl设定的用户进行访
```
　　配置完之后重启 squid
```python
squid -k reconfig

#or

squid restart
```
　　这时候如果一切顺利，你再次使用这台机器的 squid 代理就需要账号密码验证了

#### 检测端口是否打开

　　如果你发现没法使用配置好的 squid 代理，我们需要检测是不是机器的防火墙是否拦截住了这个端口
```python
telnet ip port
```
　　如果返回以下结果
```python
Trying ip...
Connected to ip.
Escape character is '^]'.
```
　　那就说明端口是开放的
　　如果连接不上，那么我们关闭防火墙

service firewalld stop
##### 若端口还是没打开

　　博主常用的是腾讯云和阿里云，到目前为止 (2019/05/13)，一般腾讯云的机器是没有屏蔽流量出入端口的，但是阿里云需要设定<font color="red">**开放安全组**</font>，这里就不多作说明，百度搜索关键词<font color="red">**阿里云设定开放安全组端口**</font>.

#### 验证验证是否生效
```python
wget
wget -e "http_proxy=http://username:pass@ip:port/" "http://www.baidu.com"

curl
curl -x"http://username:pass@ip:port/" "http://www.baidu.com"

requests
print requests.get("http://www.baidu.com",proxies={'http': 'http://username:pass@ip:port/'}).content
```
#### 本地搭建 squid，使用需要认证的 squid 代理

　　直接安装配置即可，在配置 squid.conf 的时候需要注意修改如下部分
```python
#其中的ip port 即是按照如上配置的公网机器的ip和端口
cache_peer ip parent port 0 login=user:pass no-query weighted-round-robin weight=1 connect-fail-limit=2 allow-miss max-conn=5 name=001
```
　　写入多个 ip port 即可
　　即是在常规的配置之上加上了以下一项，且这一项最好放在前面，不要放在末尾
```python
login=user:pass
```
　　之后我们重启本地的 squid，即可直接使用，不需要加上账号密码了
```python
curl "http://www.baidu.com" -x 127.0.0.1:8888
```
### End

　　由于之前半年有些重要的事情停滞了写博客这件事，后续会慢慢补上的~~
