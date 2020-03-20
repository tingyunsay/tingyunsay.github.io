---
title: 细说python字符编码(三)
date: 2017-10-15 12:12:54
tags: [编码,html实体]
categories: [python]
---
### 本文介绍编码中的html实体（编码）
<!-- more -->
### 背景
继昨天在整理好之前的两篇字符编码笔记之后，本来觉得豁然开朗，对编码这东西应该不会再遇到什么难题了
谁知道今天早上刚回来工作又遇到一种奇怪的编码方式 …（⊙＿⊙；）…
### html编码
之前讨论过的都是属于字符串编码，从网页上抓取到的数据一般也是unicode字符，但这回莫名其妙在数据库中看到了大量 &#xx; 字符如下
```text
[ti&#58;Saving&#32;All&#32;My&#32;Love&#32;For&#32;You]&#10;
[ar&#58;Whitney&#32;Houston]&#10;
[al&#58;237436]&#10;
[offset&#58;0]&#10;
[00&#58;00&#46;10]
Saving&#32;All&#32;My&#32;Love&#32;For&#32;You&#32;&#45;&#32;Whitney&#32;Houston&#10;
[00&#58;00&#46;20]Written&#32;by&#32;：Michael&#32;Masser&#124;Gerry&#32;Goffin&#10;
[00&#58;00&#46;30]&#10;
[00&#58;14&#46;65]A&#32;few&#32;stolen&#32;moments&#32;is&#32;all&#32;that&#32;we&#32;share&#10;
[00&#58;22&#46;09]You&#39;ve&#32;got&#32;your&#32;family&#32;and&#32;they&#32;need&#32;you&#32;there&#10;
[00&#58;28&#46;87]Though&#32;I&#39;ve&#32;tried&#32;to&#32;resist&#32;being&#32;last&#32;on&#32;your&#32;list&#10;
[00&#58;36&#46;27]But&#32;no&#32;other&#32;man&#39;s&#32;gonna&#32;do&#10;
[00&#58;43&#46;29]So&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#32;for&#32;you&#10;
[00&#58;54&#46;94]It&#39;s&#32;not&#32;very&#32;easy&#32;living&#32;all&#32;alone&#10;
[01&#58;01&#46;67]My&#32;friends&#32;try&#32;and&#32;tell&#32;me&#32;find&#32;a&#32;man&#32;of&#32;my&#32;own&#10;
[01&#58;08&#46;91]But&#32;each&#32;time&#32;I&#32;try&#32;I&#32;just&#32;break&#32;down&#32;and&#32;cry&#10;
[01&#58;16&#46;14]Cause&#32;I&#39;d&#32;rather&#32;be&#32;home&#32;feeling&#32;blue&#10;
[01&#58;23&#46;35]So&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#32;for&#32;you&#10;
[01&#58;31&#46;72]You&#32;used&#32;to&#32;tell&#32;me&#32;we&#39;d&#32;run&#32;away&#32;together&#10;
[01&#58;39&#46;07]Love&#32;gives&#32;you&#32;the&#32;right&#32;to&#32;be&#32;free&#10;
[01&#58;45&#46;30]You&#32;said&#32;be&#32;patient&#32;just&#32;wait&#32;a&#32;little&#32;longer&#10;
[01&#58;52&#46;58]But&#32;that&#39;s&#32;just&#32;an&#32;old&#32;fantasy&#10;
[02&#58;00&#46;26]I&#39;ve&#32;got&#32;to&#32;get&#32;ready&#32;&#32;just&#32;a&#32;few&#32;minutes&#32;more&#10;
[02&#58;06&#46;86]Gonna&#32;get&#32;that&#32;old&#32;feeling&#32;when&#32;you&#32;walk&#32;through&#32;that&#32;door&#10;
[02&#58;14&#46;07]For&#32;tonight&#32;is&#32;the&#32;night&#32;for&#32;feeling&#32;alright&#10;
[02&#58;21&#46;44]We&#39;ll&#32;be&#32;making&#32;love&#32;the&#32;whole&#32;night&#32;through&#10;
[02&#58;28&#46;59]So&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#10;
[02&#58;32&#46;19]Yes&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#10;
[02&#58;35&#46;80]Yes&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#32;for&#32;you&#10;
[02&#58;47&#46;71]No&#32;other&#32;woman&#32;&#32;is&#32;gonna&#32;love&#32;you&#32;more&#10;
[02&#58;54&#46;05]Cause&#32;tonight&#32;is&#32;the&#32;night&#32;that&#32;I&#39;&#39;m&#32;feeling&#32;alright&#10;
[03&#58;01&#46;38]We&#39;ll&#32;be&#32;making&#32;love&#32;the&#32;whole&#32;night&#32;through&#10;
[03&#58;08&#46;42]So&#32;I&#39;m&#32;saving&#32;all&#32;my&#32;love&#10;
[03&#58;12&#46;23]Yeah&#32;I&#39;&#39;&#39;&#39;m&#32;saving&#32;all&#32;my&#32;love&#10;
[03&#58;15&#46;85]Yes&#32;I&#39;&#39;&#39;&#39;m&#32;saving&#32;all&#32;my&#32;love&#32;for&#32;you&#10;
[03&#58;27&#46;06]For&#32;you&#32;&#32;for&#32;you
```
这是一份歌词页面，在其中发现大量的字符如下
```
&#10; &#32; &#39; 
```
在网上查阅后知道这是html编码，并且其中有如下对应关系
```text
&#10;  ---     换行  "\n"

&#32;  ---     空格  " "

&#39;  ---     撇号  "'"
```
![图片1](/细说python字符编码03/1.png)
![图片2](/细说python字符编码03/2.png)
更详细的可以在[<font color="red">这里</font>](http://www.w3school.com.cn/tags/html_ref_ascii.asp)查找,我们这里暂时只有用到ascii的html编码，后面必然会带有一个冒号，注意<font color="red">一些中文的html编码可能并不带有后面那个冒号</font>
### 乱码解决
```python
#!/usr/bin/env python
#!coding:utf-8
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import HTMLParser
import chardet

def html2utf8(html):
    str_html = html
    t = HTMLParser.HTMLParser()
    str_utf8 = t.unescape(str_html).encode('utf8')
    return str_utf8

if __name__=="__main__":
    html = r"&#39;"
    print html2utf8(html)

    print chardet.detect(html)
    print chardet.detect(html2utf8(html))

#>>> '
#>>> {'confidence': 1.0, 'language': '', 'encoding': 'ascii'}
#>>> {'confidence': 1.0, 'language': '', 'encoding': 'ascii'}
```
使用HTMLParser.HTMLParser()的unescape方法，之后再将得到的unicode字符encode成utf8
最后得到的结果如下
```text
[ti:Saving All My Love For You]
[ar:Whitney Houston]
[al:237436]
[offset:0]
[00:00.10]Saving All My Love For You - Whitney Houston
[00:00.20]Written by ：Michael Masser|Gerry Goffin
[00:00.30]
[00:14.65]A few stolen moments is all that we share
[00:22.09]You've got your family and they need you there
[00:28.87]Though I've tried to resist being last on your list
[00:36.27]But no other man's gonna do
[00:43.29]So I'm saving all my love for you
[00:54.94]It's not very easy living all alone
[01:01.67]My friends try and tell me find a man of my own
[01:08.91]But each time I try I just break down and cry
[01:16.14]Cause I'd rather be home feeling blue
[01:23.35]So I'm saving all my love for you
[01:31.72]You used to tell me we'd run away together
[01:39.07]Love gives you the right to be free
[01:45.30]You said be patient just wait a little longer
[01:52.58]But that's just an old fantasy
[02:00.26]I've got to get ready just a few minutes more
[02:06.86]Gonna get that old feeling when you walk through that door
[02:14.07]For tonight is the night for feeling alright
[02:21.44]We'll be making love the whole night through
[02:28.59]So I'm saving all my love
[02:32.19]Yes I'm saving all my love
[02:35.80]Yes I'm saving all my love for you
[02:47.71]No other woman is gonna love you more
[02:54.05]Cause tonight is the night that I''m feeling alright
[03:01.38]We'll be making love the whole night through
[03:08.42]So I'm saving all my love
[03:12.23]Yeah I''''m saving all my love
[03:15.85]Yes I''''m saving all my love for you
[03:27.06]For you for you"}
```
以utf8的格式保存的，这样的字符串保证到什么都不会出现乱码，okay
### End
作为一个数据提供者和可能的消费者，提供可靠的数据源是很重要的，打好基础才能使后面的路更顺利~