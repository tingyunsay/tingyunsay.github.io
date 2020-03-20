---
title: Portia---一款开源可视化爬虫工具
date: 2017-06-29 12:09:07
tags: [portia , 可视化爬虫]
categories: [portia]
---

## 本文介绍Portia的学习使用

<!-- more -->


### 背景
由于最近在写一个可供配置的爬虫模板，方便快速扩展新的抓取业务，并且最后目标是将其做成一个可视化的配置服务。还正在进行中，并且有点没有头绪，所以想参考网上现有的轮子，看看能不能找到点新的思路。

而我之前的方法是将整个网站的抓取流程写成一个同样的模式，即一层一层抓，每一层进来都做同样的几步判断（如：是否需要分页，是否需要渲染，是否是json页面，是否要进入到下一层.....）再将相同的规则代码提取出来写到一个json文件中，之后通过配置一个json文件能达到新建爬虫任务的需求。

但事实是遇到的页面情况太多太杂，所以还远远不能达到通用的效果。由此，开始看轮子之路。

### 安装portia

#### 方法一:Docker
此处参考[<font color="red">**官方文档**</font>](http://portia.readthedocs.io/en/latest/installation.html)
```shell
# < ..FOLDER> 路径自定义即可 ， 可在后面加上portia的版本
docker run -i -t --rm -v <PROJECTS_FOLDER>:/app/data/projects:rw -p 9001:9001 scrapinghub/portia

# git上是如下语句
docker run -v ~/portia_projects:/app/data/projects:rw -p 9001:9001 scrapinghub/portia
```
等待拉取完之后即可在9001端口看到portia的服务页面。但是拉取的过程实在是太慢，由于docker需要拉取的镜像实在太大，直接从国外网站下拉根本拉不到，所以这里我们需要使用到阿里云的docker加速器。

具体方法参见[<font color="red">**阿里云docker加速器**</font>](https://cr.console.aliyun.com/#/accelerator)

#### 方法二:在Virtualenv虚拟环境中安装
[<font color="red">参考网站</font>](http://www.codeweblog.com/%E3%80%8E%E7%9B%97%E6%A2%A6%E7%A9%BA%E9%97%B4%E3%80%8F%E7%A5%9E%E5%99%A8-portia%E4%BD%BF%E7%94%A8%E6%96%B9%E6%B3%95%E7%AE%80%E8%BF%B0/)
```python
pip install virtualenv

virtualenv tingyun

source tingyun/bin/activate

cd tingyun

git clone https://github.com/scrapinghub/portia

cd portia/

#安装必要的包
sudo ./provision.sh install_deps install_splash install_python_deps

#启动环境
export PYTHONPATH='/你的路径/portia_server:/你的路径/slyd:/你的路径/slybot'
slyd/bin/slyd -p 9002 -r portiaui/dist &
portia_server/manage.py runserver

```

安装完成后通过进入 <a>http://localhost:9001/static/main.html</a>

注：这里安装报错，在Ubuntu16.04，python2.7.13下。提示PyQt未安装。最后博主并没有用这种办法安装成功，需要踩的坑太多了，选择了放弃。（具体遇到的错误，可以查看这篇博文:[<font color="red">centos7安装Portia记录</font>](https://www.biaodianfu.com/centos-7-install-portia-log.html)）


### 使用

#### 新建project
点击　New spider 创建一个新的spider
右边侧栏会提示你输入一个url，Portia会将网页的url作为一个start page。
这个start page一般被用来当做seek（种子），用来获得更多的链接。

<font color="blue">**图1**</font>
![示例图1](/Portia-一款开源可视化爬虫工具/1.jpg)

Portia支持创建 page sample（页面样本），当你创建了一个页面样本，就可以调度后面的任务按照你设定的模板抓取元素。（所以我们需要先创建这样的模板）

#### page sample

创建了sample之后，我们可以开始注释页面。注释会将页面中的一条数据链接到项目字段。这些即是我们想要提取的数据

<font color="blue">**图2**</font>
![示例图2](/Portia-一款开源可视化爬虫工具/2.jpg)

<font color="blue">**图3**</font>
![示例图3](/Portia-一款开源可视化爬虫工具/3.jpg)

如图中所示：
	第一步：1.我们鼠标移到页面中，会出现类似图中的+（加号），选中想要的数据并点击它
	第二步：2中出现一个新的字段field1，field2....(如图三)，可以自己更改字段的名字，重复第二步标识所有需要的字段
	第三步：再选中3中的按钮，去点击你之前选中的元素（你就朝着不同颜色点一下就行了），Portia会自动标识出所有其他相同的元素，并在页面上以相同颜色显示

到此操作结束

可以在最右侧看到我们选中的项目，将所有需要提取的items注释完之后，关闭样本。Close Sample，如果以后需要再添加其他元素，继续配置此样本，方便后续的抓取。

最后，我们可以在右边看到我们需要的数据，json如下格式
<font color="blue">**图4**</font>
![示例图4](/Portia-一款开源可视化爬虫工具/4.jpg)

#### 配置抓取 

为了抓取某个站点，Portia需要一个或多个urls作为种子页面，才能去访问更多的links。我们需要在START PAGES中定义这些种子urls。点击添加，输入即可。

1.在START PAGES 这里ADD feed URL，按下enter键，添加成功
2.或者右边的浏览器那一栏输入网址，<font color="red">**等加载完网址**</font>，点击网址栏右边的Satrt page，默认是不选中的（表示将其添加到START PAGES中去）,添加成功

<font color="blue">**图5**</font>
![示例图5](/Portia-一款开源可视化爬虫工具/5.jpg)

本人推荐第二种，添加的同时能直接看到提取效果

Portia会用你选中的sample page去解析这些Start pages，最右侧栏会显示当前url提取出的数据

到这里，操作结束

#### 添加过滤规则

默认情况下，Portia遵循所有域内URL。在许多情况下，我们需要限制Portia将访问的页面（否则会无边无际去抓取...）
这里，我们通过设定<font color="blue">**跟随(follow)白名单**</font>和<font color="blue">**排除黑名单**</font>的模式。可以通过更改<font color="blue">**配置URL模式**</font>来配置这些

for example: Amazon产品的URL包含/gp/，因此可以将其设定为follow（跟随）模式，Portia将会只知道这样的URL

#### 启动程序

我们配置好了sample page和start pages，那么就要开始抓取数据了，也就是将数据保存到json文件或者数据库中。这里我们保存成json文件
```
官方给出的代码如下
docker run -i -t --rm -v PROJECTS_FOLDER:/app/data/projects:rw -v OUPUT_FOLDER:/mnt:rw -p 9001:9001 scrapinghub/portia \ 
portiacrawl /app/data/projects/PROJECT_NAME SPIDER_NAME -o /mnt/RESULT.json
```
其中可以更改的是大写的那些部分：<font color="red">PROJECTS_FOLDER /  OUPUT_FOLDER / PROJECT_NAME /  SPIDER_NAME /  RESULT.json </font>
依次是： 项目名	/  输出目录  /  project的名字 / Spider名字 /  保存结果的文件


启动程序前必须先关闭Portia的调试页面，这里我直接使用kill命令，因为我在docker启动的终端按下ctrl+c 或 crtl+z都无效，只能用进程关闭

例如，我的启动代码如下：
```python
docker run -i -t --rm -v ~/portia_projects:/app/data/projects:rw -v ~/result:/mnt:rw -p 9001:9001 scrapinghub/portia \ 
portiacrawl /app/data/projects/tingyun tingyun.site -o /mnt/tingyun.json
```

运行成功就能看见代码在飞快地跑了，而且都是我们想要的items

运行完成，数据保存在设定我output_floder中，我们这里是~/result/下，如图
<font color="blue">**图6**</font>
![示例图6](/Portia-一款开源可视化爬虫工具/6.jpg)

可以看到我们有77行数据，文件名为tingyun.json，路径是~/result/

切进去看具体的数据
<font color="blue">**图7**</font>
![示例图7](/Portia-一款开源可视化爬虫工具/7.jpg)

圈出来的部分可以看出来，即是其中一个start page中的内容。

### 总结

到此，我们就结束了这一次使用Portia的抓取之旅，通过使用Portia确实能实现很快速简易的抓取功能，能将抓取过程可视化得呈现给操作者，还有其他有趣的功能在后续的学习中遇到再次分享给大家，接下来会去考虑试着将其用到一些大规模的抓取上，看看到底效果如何

未完待续.....



