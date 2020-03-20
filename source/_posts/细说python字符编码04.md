---
title: 细说python字符编码(四)
date: 2018-06-22 00:30:02
tags: [编码,自定义编码]
categories: [python]
---
### 本文介绍网络反爬中使用到的字体反爬---自定义字符编码
<!-- more -->
### 背景
前段时间的一些工作是关于抓取小说，在实际操作中遇到了一种新鲜的东西，也就是开头说到的字体反爬  
这个问题最初遇到是在起点小说（貌似携程对于机票的价格也是这么做的），所以接下里主要以起点为例子说明解决方法
### 字体反爬
自定义字体：
　　@font-face是CSS3中的一个模块，主要是实现将自定义的Web字体嵌入到指定网页中去。具体详细定义见[<font color="purple">**CSS @font-face**</font>](https://link.zhihu.com/?target=https%3A//www.cnblogs.com/fjdingsd/p/5663561.html)

先简单了解下上面提到的自定义字体概念，大致能够理解：所谓字体反爬，就相当于是自己定义了一个仅仅属于自己的小型字符集和，看过我们前面的[<font color="red">**细说python字符编码(二)**</font>](http://tingyun.site/2017/10/15/%E7%BB%86%E8%AF%B4python%E5%AD%97%E7%AC%A6%E7%BC%96%E7%A0%8102/)应该都能大致了解到所谓“编码”这个概念------定义了一套基础字符集的规定。unicode是一种，utf8是一种，这里的自定义编码也是一种

我们要做的，<font color="red">**是将这种自定义编码的格式转换成我们能识别的utf8的格式**</font>

起点中文网示例如下图
![图片1](/细说python字符编码04/1.jpg)
### 解决方法
#### 思路
　　既然其在前端自定义了一套编码规则，且我们的肉眼也能看到，就说明其解码编码也都在前端被完成了。我们只要模拟浏览器在前端所做的操作即可：<font color="red">**重新解码并编码这些自定义字体**</font>
#### 编码/解码
　　在前端页面中找到编码相关的<font color="red">**协议家族**</font>
![图片2](/细说python字符编码04/2.png)
　　把图中的代码粘贴如下
```python
@font-face { 
    font-family: GyakqlyW; 
    src: url('https://qidian.gtimg.com/qd_anti_spider/GyakqlyW.eot?') format('eot'); 
    src: url('https://qidian.gtimg.com/qd_anti_spider/GyakqlyW.woff') format('woff'), url('https://qidian.gtimg.com/qd_anti_spider/GyakqlyW.ttf') format('truetype'); 
    } 
.GyakqlyW { 
    font-family: 'GyakqlyW' !important;
    display: initial !important; 
    color: inherit !important; 
    vertical-align: initial !important; 
    }
```
　　其中博主所使用到的是这个woff的url，且从其中易知道，这个协议的名字就叫做：GyakqlyW
　　得到这个协议族的映射表的代码如下
```python
from fontTools.ttLib import TTFont
from io import BytesIO
import requests

    crawl_config = {
        'headers':{
            'Referer':'https://www.qidian.com/',
            'Upgrade-Insecure-Requests':'1',
            'User-Agent':'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36'
        }
    }

    family_font = "GyakqlyW"
    font = TTFont(BytesIO(requests.get("https://qidian.gtimg.com/qd_anti_spider/%s.woff"%family_font,headers=crawl_config['headers']).content))        
    qidian_map = font.getBestCmap()
    font.close()
```
　　以上代码中得到的qidian_map就是我们用来转换的编码规则
　　输出如下
```python
{100494: 'eight', 100496: 'five', 100497: 'six', 100498: 'four', 100499: 'two', 100500: 'period', 100501: 'one', 100502: 'three', 100503: 'zero', 100504: 'seven', 100505: 'nine'}
```
　　到这里我们就能看到一些有意思的东西了，一些六位的数字和１到９的英文单词，对了还有一个period翻译是"点"的意思，我们再拿出来直接从起点中文网的网页中提取到的字体数据
![图片３](/细说python字符编码04/3.png)
　　其中的数据除了前两位正好也是六位的数字，那么看看他们之间有没有对应的关系.看途中第一个高亮的部分，是字数对应的部分
```python
&#100504;&#100498;&#100500;&#100496;&#100497;

100504  -   seven   -   7
100498  -   four    -   4
100500  -   period  -   .
100496  -   five    -   5
100497  -   six     -   6

合起来就是74.56 ，加上后面的"万字"，就是图二中所显示的 74.56万字
```
　　到这里，我们可以确定我们想要的结果了
　　只需要记得我们每次操作都需要动态去获取不同的协议家族，然后按照以上的方法去解码即可
### 代码
　　详细代码我稍加整理后会放到git上去，暂时只贴出来核心部分的代码,其是使用pyspider 进行编写的，所以其中的response均是http请求返回的内容，经过pyquery包装的对象
```python
from pyspider.libs.base_handler import *
import re
from fontTools.ttLib import TTFont
from io import BytesIO
import requests
from pyquery import PyQuery
from lxml import etree


    #要根据当前的协议家族，请求不同的 协议定义网址，得到对应的 映射表，再进行字体转换
    family_font = response.doc('em > span').attr['class']
    font = TTFont(BytesIO(requests.get("https://qidian.gtimg.com/qd_anti_spider/%s.woff"%family_font,headers=self.crawl_config['headers']).content))        
    qidian_map = font.getBestCmap()
    font.close()

    #print response.doc('em > span').eq(1).text().encode().decode('Windows-1252').encode('utf8')
    html = etree.HTML(response.text)
    word = html.xpath('//em/span')
    
    word_encry = etree.tostring(word[0])
    word_encry = re.search("(?<=\>).*(?=\<)",word_encry).group()
    word_counts = get_num(qidian_map,word_encry)
    
    click_encry = etree.tostring(word[1])
    click_encry = re.search("(?<=\>).*(?=\<)",click_encry).group()
    click_counts = get_num(qidian_map,click_encry)
    
    tuijian_encry = etree.tostring(word[2])
    tuijian_encry = re.search("(?<=\>).*(?=\<)",tuijian_encry).group()
    tuijian_counts = get_num(qidian_map,tuijian_encry)
```
----------------------------------------------

### End
　　写得比较匆忙，周末再整理一下，有什么错误还请指出，感激不尽！