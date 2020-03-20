---
title: python2.6.6更换2.7
date: 2017-09-09 15:18:09
tags: [系统 , python]
categories: [pyspider]
---
## 本文介绍为centos6.5更换python版本
<!-- more -->
### 前言
本文接前一篇博文中提到的python2.6.6更换2.7，主要是针对配置pypsider需要注意的一些点所写的，包含了mysql / pycurl / sqlite3 等模块的安装
### 安装python2.7
可以去python的[**<font color="purple">ftp站点</font>**](https://www.python.org/ftp/python/ "python")下载，如果觉得慢的换，我在csdn上传了一个[**<font color="purple">python2.7.11版本</font>**](http://download.csdn.net/download/tingyun_say/9739573 "csdn")供下载

解压
```shell
tar -jxvf Python-2.7.xx.tar.bz2
```
注: 这个时候千万不要急着去编译安装，**<font color="purple">首先将一些pyspider所用到的一些库的依赖安装好</font>**，否则你安好的python2.7也会在启动pyspider过程中报错
```shell
yum install sqlite-devel -y

yum -y install libcurl libcurl-devel
```
编译安装
```shell
cd /Python-2.7.xx/

#configure默认是将软件安装到/usr/local/bin/ 中，也可以手动指定路径 --prefix 
./configure

make && make install
```
替换掉yum的依赖
由于我们的yum依赖的是2.6.6版本的python，所以我们需要保存留下python2.6.6，并且在yum的头文件中指定引用到旧版本的python，如下操作
```shell
mv /usr/bin/python /usr/bin/python2.6.6

vi /usr/bin/yum
#将第一行换成
#!/usr/bin/python2.6.6

#最后将新的py软链接到环境中
ln -s /usr/local/bin/python /usr/bin/python
```
这样一来yum即不会受影响

### 安装pip及其他包
先去官网下载get-pip.py
https://bootstrap.pypa.io/get-pip.py

设定国内源，安装后续的软件包
```shell
mkdir ~/.pip

touch ~/.pip/pip.conf

vi ~/.pip/pip.conf

#添加如下内容
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=mirrors.aliyun.com

#这时候再安装pip，使用清华的源，不需等待
python get-pip.py

pip install -U setuptools

pip install pyspider
```

如果有相关mysql的报错如下
```shell
error: option --single-version-externally-managed not recognized
```
解决
```shell
pip install --egg mysql-connector-python-rf
```
### End
至此，关于对应py2.7的pyspider已经安装完毕，可以尽情地去使用pyspider的分布式或单机搭建了

