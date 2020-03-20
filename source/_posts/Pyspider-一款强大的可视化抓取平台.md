---
title: Pyspider---一款强大的可视化抓取平台
date: 2017-07-08 19:30:31
tags: [pyspider , 可视化爬虫]
categories: [pyspider]
---

## 本文介绍Pyspider的使用

<!-- more -->

### 背景
续上一篇，Pyspider也是网上比较出名的开源可视化爬虫框架，所以在尝试过Portia之后就开始使用它。对于它两的可视化其实都差不多，都是通过点击css选择器自动生成抓取规则。pysipder写了一个可视化的控制页面，让你能看见你的抓取任务的状况（速度/工作情况/抓取结果....），并且能通过配置下载速度和并发数控制抓取的快慢。且有追踪的log日志，记录了抓取过的每一条url链的情况

通过一个星期的使用，决定将之前的抓取任务都迁移到pyspider上，并考虑在后续为其添加字段检验的功能
### 安装Pyspider

```python
pip install pyspider
```

<font size=4 color="red">Focus</font>	Centos安装正常，Ubuntu安装过程中出现错误，模块pycurl安装失败，解决方法
```python
apt-get install python-pycurl

pip install pyspider
```

默认启动直接输入 pyspider即可，输入[<font colot="red">localhost:5000</font>](localhost:5000)进入到我们的控制台

可以指定config.json文件启动
```
{
 "webui": {
 	"port": 33333,
     	"username": "tingyun",
	"password": "helloworld",
	"need-auth": true
	}
}
```
更多配置参考[<font color="red">pyspider中文网</font>](http://www.pyspider.cn/book//Deployment-6.html)
### Demo---抓取腾讯视频的电影信息
这里我们来实际抓取一个网站，入门pyspider的使用
#### Create Project
点击控制面板中的Create，输入如下信息
![示例图1](/Pyspider-一款强大的可视化抓取平台/1.jpg)
project的名字不可更改，但你注意我这里的Start Url是随便填的，因为在项目中是可以随便改变的
#### 编写代码
Sample Code
![示例图2](/Pyspider-一款强大的可视化抓取平台/2.jpg)
代码的基本含义
```
crawl_config	全局设定，遇到反爬的情况需要在其中配置对应的措施(如代理,UA,Cookies,渲染  
....)，当然你也可以在下面的crawl函数中局部设定

on_start	项目的入口，self.crawl("Start Url",callback=self.index_page)，  
这里传递进来了你在创建项目的初始url.只能存在一个

self.crawl	项目的核心函数，支持多个参数，默认是待爬url和callback函数.将抓取url的  
response返回给callback函数

index_page	回调函数，名字不重要，只需要你在callback的时候写好对应的函数名，可以  
有多个

detail_page	处理详情页，将处理结果以json格式的result返回给结果处理函数on_result

on_result	默认是存储到data目录下的result.db中，可以显示申明重写这个函数，其参数为  
(self , result)
```
##### Write Code
首先更改我们找到的入口页面，腾讯视频下的电影类别分类http://v.qq.com/x/list/movie?subtype=-1&offset=0
```
@every(minutes=24 * 60)
    def on_start(self):
        self.crawl('http://v.qq.com/x/list/movie?subtype=-1&offset=0#0', callback=self.index_page)
```
点击左边调试栏中的run按钮，底下会出现一个follow，表示这个页面中符合你当前（index_page）crawl函数中的规则的url，默认的规则是全部能提取到的url，但我们只关心我们想要的页面，这个规则我们怎么写呢？
点击follow左边的web按钮，我们进到如下的页面，这是pyspider为你加载好的静态页面
![示例图3](/Pyspider-一款强大的可视化抓取平台/3.jpg)
<font color="blue">体现我们的可视化的时刻到了</font>，点击最左边的enable css selector helper，当你的鼠标再移到页面中，会发现鼠标移到的地方变成了黄色，这即使和Portia一样的地方。我们点击下图红色框中的copy按钮，粘贴到index_page中第一个self.crawl()中去
![示例图4](/Pyspider-一款强大的可视化抓取平台/4.jpg)
```
@config(age=10 * 24 * 60 * 60)
def index_page(self, response):
    for each in response.doc('.figure_title > a').items():
	self.crawl(each.attr.href, callback=self.detail_page)
```
因为这些页面是我们的final_page，所以直接回调给detail_page
继续往下拉，我们能看到很多的分页，我们让项目按照下一页的方式进行抓取，同理用enable css selector helper选出下一页的css规则再写一个crawl函数。下一页的解析规则和这一页是一样的，都是将这一页的final_page回调给detail_page，同时继续分析下一页
<font color="blue">合起来的代码即是</font>
```
@config(age=10 * 24 * 60 * 60)
    def index_page(self, response):
        for each in response.doc('.figure_title > a').items():
            self.crawl(each.attr.href, callback=self.detail_page)
        self.crawl([x.attr.href for x in response.doc('[class="page_next"]').items()],callback=self.index_page)
```
##### Detail Page
这里就是类似上一步的过程重复了，pyspider内置了一个pyquery解析response，并将得到的结果填充到对应的字段中
<font color="blue">**常用的有**</font>
```
response.doc('css rules').text()  /  resposne.content  /  response.json['key1']['key2']....
```
```
@config(priority=2)
    def detail_page(self, response):
        return {
            "url": response.url,
            "site_name":"tencent_movie",
            "movie_name":response.doc('._base_title').text(),
            "publish_time":re.search("(?<=uploadDate\" content=).*(?=/)",response.content).group(),
            "primary_stars":response.doc('.video_info_cell_2 > div:contains("导演")').text().split(' ')[3:],
            "director":response.doc('.video_info_cell_2 > div:contains("导演")').text().split(' ')[1],
            "area":re.search("(?<=contentLocation\" content=).*(?=/)",response.content).group(),
            "style_classify":response.doc('.video_info_cell_1 a').text(),
            "language":re.search("(?<=inLanguage\" content=).*(?=/)",response.content).group(),
            "comment_counts":response.doc('[id="commentTotleNum"] > a').text(),
            "introduce":re.search("(?<=description\" content=).*?(?=>)",response.content,re.S).group(),
            "fav_counts":None,
            "step_counts":None,
            "score_level":response.doc('.video_score').text(),
            "score_counts":None,
            "fans_counts":None,
            "index":response.doc('.douban_score > .num').text(),
            "evaluation_counts":None,
            "vote_counts":None,
            "play_counts":response.doc('.icon_text > em').text(),
            "duration":float(re.search(r"(?<=duration\":\")\d+?(?=\")",requests.get("https://union.video.qq.com/fcgi-bin/data?otype=json&tid=682&appid=20001238&appkey=6c03bbe9658448a4&idlist={list_id}".format(list_id=[x.attr.id for x in response.doc('[class="player_figure"]').items()][0])).content).group())/3600,

        }
```
python的可操作性是很高的，只要你引入包就什么都能做，像我在如上的代码中，因为有些数据并不能从静态网页上得到，我通过了抓包的方式找到了获取这个参数的接口，经由requests向其发送请求获取我需要的数据，最后填充到duration字段中

duration---电影的时长，为秒数，将其转换成float并除以3600s，得到时长
##### Result Test
再写完如上代码，继续点击run，检查我们的字段是不是都提取正确，像之前那种网页无法获取我们就需要使用其他方法(比如渲染，接口)
![示例图5](/Pyspider-一款强大的可视化抓取平台/5.jpg)
具体的json数据如下
```
{'area': '"美国" ',
 'comment_counts': '',
 'director': u'莱塞·霍尔斯道姆',
 'duration': 1.6683333333333332,
 'evaluation_counts': None,
 'fans_counts': None,
 'fav_counts': None,
 'index': '7.7',
 'introduce': '"影片以汪星人的视角展现狗狗和人类的微妙情感，一只狗狗陪伴小主人长大成人，甚至为他追到了女朋友，后来它年迈死去又转世投胎变成其他性别和类型的汪，第二次轮回狗狗变成了警犬威风凛凛，再次转轮回，又成了陪伴一位单身女青年的小柯基犬。在经历了多次轮回之后，最终回到最初的主人身边。"',
 'language': '"英语" ',
 'movie_name': u'一条狗的使命(英语版)',
 'play_counts': u'1.3亿',
 'primary_stars': [u'乔什·加德',
                   u'布丽特·罗伯森',
                   u'丹尼斯·奎德'],
 'publish_time': '"2017-03-03" ',
 'score_counts': None,
 'score_level': '8.8',
 'site_name': 'tencent_movie',
 'step_counts': None,
 'style_classify': u'美国 剧情 喜剧',
 'url': 'https://v.qq.com/x/cover/950h5k5p7h7m2qn.html',
 'vote_counts': None}
```
敲完代码，或者将如上三段代码粘贴到你的项目中，点击右上角的saved，再用run测试下我们的代码，没有出现错误即可回到我们的控制台
#### 运行Demo
当我们修改完代码，默认项目的status会变成亮黄色的CHECKING。点击它，将其设定成RUNNING，确定.
![示例图6](/Pyspider-一款强大的可视化抓取平台/6.jpg)
最后点击这一行最右侧的Run按钮，点击完如果你的任务执行得快的话，能看见run左边的任务状态栏的颜色由灰色变成了蓝色，表示任务开始

<font color="red">**查看当前的任务状态，点击Run旁边的Active Tasks，能看到最近抓取记录，在其中你能追踪任务的状态以及查看任务失败的原因**</font>
![示例图7](/Pyspider-一款强大的可视化抓取平台/7.jpg)
如图所示表面这条链接已经被放在tasks队列中，其原因有两种:1.任务被暂停	2.失败重试，该链被放到tasks队列的尾部等待重试

上图中的这条链接是失败重试的链，具体错误信息也能在下拉的页面中找到，如下图
![示例图8](/Pyspider-一款强大的可视化抓取平台/8.jpg)
显示任务已经运行到了detail_page处，错误原因是list index out of range

<font color="red">**这样以来定位错的原因也变得很方便了，我此处的有两种：**</font>
1.是由于传递给接口的参数并没有找到，导致返回数据失败，错误
2.有些电影没有导演([如这部](https://v.qq.com/x/cover/q3u3zmztifdspe5.html?new=1))，导致解析失败，无法return

所以后续考虑做在抓取时候也作字段容错，单个字段出错给空置，起码保证正常的数据返回
#### 结果
![示例图9](/Pyspider-一款强大的可视化抓取平台/9.jpg)
<font color="red">**关于图中的一些字段意思如下**</font>
```
1.队列统计：方便查看爬虫状态，优化爬虫爬取速度新增的状态统计。
 每个组件之间的数字就是对应不同队列的排队数量，通常就是0或个位数，如果达到了几十甚至一百说明下游组件出现了瓶颈或错误，需要分析处理

2.组名：新建project后一般是不能修改project名字，如果需要特殊标记，可以通过更改group名字。
  注：组名改为delete后如果状态是stop状态，24小时后会被系统自动删除

3.运行状态：五个
     TODO ： 新建项目后的默认状态
     STOP ：　停止
     CHECKING ：只要修改了代码，自动变成检查状态
     DEBUG ：在这个模式下运行，遇到错误信息会停止继续运行
     RUNNING :  这里运行时遇到错误会尝试，如果还是错误会跳过这个任务继续运行

4.速度控制：rate是每秒爬取页面数 ， burst是并发数 ，如1/3是三个并发，每秒爬取一个页面。

5.简单统计：5m是五分钟内任务执行的情况 ， 1h是一小时内任务统计 ， 1d是一天内运行任务统计 ， all是所有任务统计

6.任务列表：显示最新任务列表，方便查看状态，查看错误等

7.结果查看：查看项目爬取的结果（默认是保存到sqlite3 db中，支持以json和csv格式下载）
```
更详细的解释可以查看[<font color="red">官方解释</font>](http://www.pyspider.cn/jiaocheng/pyspider-webui-12.html)

点击Result可以查看到抓取到的数据，点击下载或者使用
```
wget http://127.0.0.1:5000/results/dump/tencent_movie.json
```
获取结果到当前路径


### End
下章会对使用pyspider的使用过程中遇到的各种情况作一个总结，踩坑模式开启
未完待续.....





