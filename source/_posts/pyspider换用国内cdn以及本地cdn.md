---
title: pyspider换用国内cdn/本地cdn
date: 2018-02-07 00:51:54
tags: [pyspider , cdn]
categories: [pyspider]
---
### 本文介绍使用pyspider切换国内cdn/本地cdn文件的操作

<!-- more -->
### 问题来源
由于现在大量的的抓取工作都放在pyspider这个平台上，所以每天何时何地都需要登录/并且查看修改相关任务这种是必须要的，而且是不能有任何延时的
但就是在这个要求下，pyspider却总是会进入不了主页面，什么原因呢？
其加载失败的相关信息是
<font color="purple">***.cloudflare.com加载失败**</font>

也就是说，pyspider的依赖这个网站中的一些js/css文件，但是由于这个站点经常挂（在国内，或者说电信网的问题），不得不考虑将这个依赖去掉，换成本地的文件，或者切换到国内比较靠谱的cdn
### 原因
查阅了一些cloudflare.com的相关问题，在V2EX上看见了挺多的回答的，其中有一些还是挺犀利的，摘抄如下
```text
1.CloudFlare is fast in the world except in China.

2.加钱世界可达------中国奠信

3.在下列哪些时候可以认为中国不属于地球？ 
  A 看好莱坞最新大片 
  B 玩 XBOX ONE 游戏 
  C 买联想笔记本 
  D 用阿里云

4.cloudflare:this guo me no bei

5.世界网络分为中国以及 rest of the world 
通常来说， global 的具体范围是后者
也可以说将 global 翻译为全球正越来越不准确
```
cloudflare在国外的加速效果可以说是很恐怖的，<font color="red">在全球范围其他绝大部分地方都能达到1ms以下，相比国内几十几百ms，效果不多说了</font>，并且其还是免费版本（已经足够用了），只有具有防ddos的服务的话需要加钱

大家可以使用这个网址去查看www.cloudflare.com的各个地方的线路是否出了问题：[<font color="red">**cloudflare测速**</font>](http://ping.chinaz.com/www.cloudflare.com)
#### 总结
总之就是说cloudflare.com想要在国内稳定使用还是有点不现实的，所以我接下来开始解决这个问题
### 找到依赖的js/css文件
这个方法很简答了，开启pyspider，打开浏览器登录主页，打开F12，查看network选项（正常抓包即可），刷新页面，其中会加载45个请求，去重地将这些请求都记录下来，然后去对应的网站上下载对应的文件到本地，后续再换用本地路径即可
#### 这里我找到的js/css文件如下
```text
https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/codemirror.min.css

https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.0.3/css/font-awesome.min.css

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/dialog/dialog.min.css

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/lint/lint.min.css

https://cdnjs.cloudflare.com/ajax/libs/jquery/1.11.0/jquery.min.js

https://cdnjs.cloudflare.com/ajax/libs/jsonlint/1.6.0/jsonlint.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/codemirror.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/mode/xml/xml.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/mode/css/css.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/mode/javascript/javascript.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/mode/htmlmixed/htmlmixed.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/mode/python/python.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/search/search.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/search/searchcursor.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/dialog/dialog.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/selection/active-line.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/runmode/runmode.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/lint/lint.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.20.2/addon/lint/json-lint.min.js

https://cdnjs.cloudflare.com/ajax/libs/codemirror/2.36.0/formatting.min.js

https://cdnjs.cloudflare.com/ajax/libs/URI.js/1.11.2/URI.min.js
```
### 换成国内的cdn.bootcss.com cdn
在pyspider的根目录下，vi pyspider/run.py ,其中第323行附近
```python
#@click.option('--cdn', default='//cdnjs.cloudflare.com/ajax/libs/',
@click.option('--cdn', default='//cdn.bootcss.com/',
              help='js/css cdn server')
```
在经过比对之后，我确认这和国内比较快的 //cdn.bootcss.com/ 上的文件目录都是一样的，并且测试也是都ok的

最后，将cloudflare.com这一行注释，将其换成//cdn.bootcss.com/，重新启动打开F12即可以看到现在都是向bootcss.com发送的请求了，并且相当稳定不会经常出现问题
### 换成本地cdn文件
可以写个脚本将这些文件下载到本地（最好使用国外的网络，国内不定时抽风）
后续我继续写如何将这些文件放到对应的路径以及调换本地路径，因为还没测试成功，明天继续补完这一段~>_~>（暂时还是没时间弄）

### 2018/07/20更新
由于cdn.bootcss.js这个网站暂时不提供免费的cdn服务了，但还是需要流畅使用pyspider的话，在v2ex上看到了其他的提供一样免费服务的cdn，可以替换成：//cdnjs.loli.net/ajax/libs/
```python
@click.option('--cdn', default='//cdnjs.loli.net/ajax/libs/',
               help='js/css cdn server')
```


