---
title: 动态调试本地js文件
date: 2018-03-19 23:12:56
tags: [本地js调试]
categories: [spider]
---
## 本文介绍在使用本地js替换服务器端js文件进行调试
<!-- more -->

### 前言
本文继续上一篇中末尾提到的js调试方法，其目的在于：
```text
当我们无法纯通过分析js文件中的逻辑，转换成我们的自己代码，构造请求所需要的种种参数
```

就如上一章中那种混淆过的代码，所有的参数都是a，b，c....，你根本无法知道每个参数代表什么意义，也就没法将其转换成其他的代码供自己使用，所以只好通过这种修改js代码的方式，来添加一些我们能够看得见的东西，就像一个简单的alert，可能就能解开你很多的疑惑

### 使用Fiddler
Fiddler中就附带了一个很方便的功能，可以在网页运行的时候，添加一些规则，在遇到符合规则的url时候，替换掉这些url，换成本地的文件，而对于本地的文件，我们即可以随意添加自己的操作了
基本安装什么的就不多说了，百度/谷歌一下很多，说下遇到的几个问题

#### 关于chrome抓包问题
有时候可能会发现打开chrome浏览器，访问了一些地址，fiddler中却没有任何的消息包出现，因为很长时间没使用过fiddler了，大部分时间都是用f12（pc端）或者charles（app端），所以还在网上查了一下怎么设置fiddler代理才能正常抓包

最后发现并不是fidder设置的问题，而是由于我在chrome中安装的代理插件：SwitchyOmega，不仅仅是它，经查询后发现：<font color="red">**代理插件可能会屏蔽掉除它们自己外的其他和代理相关的设置**</font>
比如fidder启动之后，会自动给浏览器设置一个127.0.0.1:8888的代理，并且强制浏览器的请求都走这个代理，但是当我们安装了代理插件之后，插件会屏蔽掉fiddler的设置，也就导致没法抓包了

**解决方法**
1.使用firefox浏览器，前提是没有安装代理插件
2.将chrome插件暂时禁用，操作完后再改回即可

#### 使用fidder进行js替换
1.在firefox中输入访问的页面：http://m.toutiao.iqiyi.com/top_126hd0mujy.html

2.在fodder中找到你要替换的js文件，我们这里是：http://static.qiyi.com/assets/js/page/detail/app_detail_video.18f1b586.js
![图一](/动态调试本地js文件/1.png)
将其<font color="red">**格式化之后**</font>，下载下来，保存路径随便定，我这里是：
<font color="purple">**/home/cas_docking/feed_crawl/aiqiyi_toutiao/app_detail_video.js**</font>
找到我们需要修改的那一段代码，我们这里如下

![图二](/动态调试本地js文件/2.png)
只加上了一段alert(n)

3.在fidder中设定映射
点击我们刚才找到的js文件，右侧第三列有一个AutoResponder，点进去，按照下图中的方式选中，以及将你的路径粘贴到最下方的栏中，点击Save
![图三](/动态调试本地js文件/3.png)

4.最后，就是重新进去到我们的浏览器中，刷新页面，不出意外就能看到如下的显示了
![图四](/动态调试本地js文件/4.png)

#### webRequest--编写自己的浏览器插件
这是另外一种方法，查阅了一些博客后，自己写一个类似功能的chrome插件，也不算是什么特别麻烦的事情，需要自己编写以下文件
```text
manifest.json
js
css
png
```
在Linux系统上，chrome插件的源码位置一般在如下路径：
```text
～/.config/google-chrome/Default/Extensions/{ID}
```
以上{ID}是chrome的插件的唯一标识，在chrome://extensions/ 中能看到每个插件的ID

有兴趣的同学可以参考下如下的网站，博主也会抽时间研究下这种方法

https://www.zhihu.com/question/20179805
https://chajian.baidu.com/developer/extensions/webRequest.html
https://www.cnblogs.com/devcjq/articles/4232029.html

-------------------------------
### End
博文中有什么问题还请发邮件给我，谢谢
