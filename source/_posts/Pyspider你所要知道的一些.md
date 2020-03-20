---
title: Pyspider所要知道的
date: 2017-07-15 00:16:12
tags: [pyspider]
categories: [pyspider]
---

## 本文介绍使用pyspider遇到的一些问题

<!-- more -->

### 背景
使用Pyspider两个星期左右的时间，已经将以前的老代码大半都迁移过来了，对其使用也有一定的了解，本文详细记录了使用pyspider可能会遇到的一些问题和解决方法

在调研pyspider的会上提到了关于用户权限控制，和对以后会存在大量任务情况下的管理措施。这是后续我们需要解决的
### Problem List
#### pyspider的去重机制
##### 问题
抓取大麦网演出（接口），分析json文件，总共约有287场演唱会，但当我的代码如下时，运行到on_finished()也只有217条数据，且任务中也没有丢出任何error
```
class Handler(BaseHandler):
    crawl_config = {
        'itag':'v98'
    }

    @every(minutes=24 * 60)
    def on_start(self):
        self.crawl('https://search.damai.cn/searchajax.html?ctl=%E6%BC%94%E5%94%B1%E4%BC%9A&order=1&currPage=1', callback=self.index_page)
    
    
    @config(age=10 * 24 * 60 * 60)
    def index_page(self, response):
        for each in enumerate(range(1,response.json['pageData']['totalPage']+1):
            self.crawl("https://search.damai.cn/searchajax.html?ctl=%E6%BC%94%E5%94%B1%E4%BC%9A&order=1&currPage={page}".format(page=each), callback=self.detail_page)
    
    @config(priority=2)
    def detail_page(self, response):
	......
```
然后发现目标和结果之间刚好差了60条数据，且大麦网一页为满的话是60条。我试着去grep第一页中的演出数据，全都不存在，也就是说丢了第一页的数据。但调试代码过程没有出现问题，猜测是去重原因
原因如下：
我使用第一页的url作为种子url，在on_star()中已经抓取过了一次，接下来我在index_page()中重新生成种子url（以及它的同级页），这时本次抓取将会对这个种子url作为忽略
<font color="red">**pyspider会对同一个任务(即同一个itag)中出现的重复url作去重，不会进行二次抓取**</font>
##### 解决方法
因为一般只会影响种子url，在种子url末尾加上 <font color="red">#xxx</font>，pyspider是对url的md5值作校验，我们只需使得其与原始url不同，不改变网页内容即可
```
class Handler(BaseHandler):
    crawl_config = {
        'itag':'v98'
    }

    @every(minutes=24 * 60)
    def on_start(self):
        self.crawl('https://search.damai.cn/searchajax.html?ctl=%E6%BC%94%E5%94%B1%E4%BC%9A&order=1&currPage=1#0', callback=self.index_page)
    
    
    @config(age=10 * 24 * 60 * 60)
    def index_page(self, response):
        for each in enumerate(range(1,response.json['pageData']['totalPage']+1):
            self.crawl("https://search.damai.cn/searchajax.html?ctl=%E6%BC%94%E5%94%B1%E4%BC%9A&order=1&currPage={page}".format(page=each), callback=self.detail_page)
    
    @config(priority=2)
    def detail_page(self, response):
	......

```
注：关于重复运行同一个任务，pyspider默认将数据存放到result.db中，当你改变itag的值(与上次不同)，那么这个任务将会重新开始，（在没改变过其他代码的前提下）意味着以前抓取过的内容会重复抓取到result.db中去

#### Pyspider组件多开
在需要提高抓取效率的时候，必然会想到分布式，在部署pyspider的时候当然也必有这一步，这里我们只测试了单机的伪造分布式，但可以作为参考

Pyspider的架构图如下
![示例图1](/Pyspider你所要知道的一些/1.jpg)
根据作者的介绍，一个调度器(scheduler)，一个或多个抓取进程(fetcher)，一个或多个处理页面进程(processor)，output是可以重写的on_result函数，默认是有一个result_worker在工作(插入数据库)，监控(monitor)和UI页面(weibui)

默认，我们的启动pyspider都是每个相关任务只启动一个，但当我们的任务数变得更多了，添加对应的处理进程会提高抓取效率和减少阻塞的情况发生
我们的多启动必须通过config文件来启动，其为一个json格式文件。其中指定了读取和插入任务的数据库，以及用作缓冲的消息队列类型
```
#这里我的pyspider项目是放在/root/下的
#用redis作为一个缓存消息队列
{
  "taskdb": "sqlite+taskdb:////root/data/task.db",
  "projectdb": "sqlite+projectdb:////root/data/project.db",
  "resultdb": "sqlite+resultdb:////root/data/result.db",
  "message_queue": "redis://127.0.0.1:6379/db",
  "webui": {
    "username": "tingyun",
    "password": "tingyun",
    "need-auth": true
  }
}
```
我们以这个配置文件后台启动pyspider，并以相同的配置启动多个processor和fetcher。processor一般在cpu的核数上 + (1 or 2)，fetcher可以多启动，它负责返回response给processor，作者说过fetcher一个大抵足够了，具体看其实现原理[<font color="red">**tornado.httpclient**</font>](http://tornado-zh.readthedocs.io/zh/latest/httpclient.html)
并将错误输出重定向到指定文件
```
nohup pyspider -c config.json > Pyspider.log 2>&1 &

nohup pyspider -c config.json processor > processor.log 2>&1 &

nohup pyspider -c config.json fetcher > fetcher.log 2>&1 &
```
多台机器的分布式下周会在公司环境上测试，大致过程类似，只需要在配置文件中添加多一些信息如ip,port等

当然你也可以通过docker部署，只需要编写一个docker-compose文件即可，如[<font color="red">**demo.pyspider.org 部署经验**</font>](https://binux.blog/2016/05/deployment-of-demopyspiderorg/)

#### 从result.db提取json文件
这个需求看起来其实没有什么必要，但是对于刚刚熟悉这个框架的同学，可能在还没有将数据重写到其他数据库或文件时，使用默认配置抓取的数据带有一些和调度相关的字段，而不是我们单纯在代码中定义的return中的json内容

##### sqlite导出
48a1faf4ce2d272807de87c798b79d2f<font color="red">**|**</font>http://music.163.com/user/home?id=31694264<font color="red">**|**</font>{"comment_counts": null, "album_counts": null, "update_time": null, "site_name": "wangyiyun_artist", "fans_counts": "140452", "mv_counts": null, "url": "http://music.163.com/user/home?id=31694264", "song_name": null, "dynamic_counts": "1", "artist_name": "\u71d5\u6c60", "song_counts": null, "style_classify": "\u7f51\u6613\u97f3\u4e50\u4eba", "play_counts": null}<font color="red">**|**</font>1499750991.01634

```shell
#默认的数据如上，带有一个 | 字符 ，这里是指定以xxx字符来替换掉那个 | 字符，分隔两边的内容
sqlite3 -separator '指定字段xxx' result.db "select * from resultdb_tablename" > res.json

#提取我抓取的网易云歌手
sqlite3 -separator "exa" result.db "select * from resultdb_wangyiyun_artist" > res.json
```
得到的res.json文件如下
48a1faf4ce2d272807de87c798b79d2f<font color="red">**exa**</font>http://music.163.com/user/home?id=31694264<font color="red">**exa**</font>{"comment_counts": null, "album_counts": null, "update_time": null, "site_name": "wangyiyun_artist", "fans_counts": "140452", "     mv_counts": null, "url": "http://music.163.com/user/home?id=31694264", "song_name": null, "dynamic_counts": "1", "artist_name": "\u71d5\u6c60", "song_counts": null, "style_classify": "\u7f51\u6613\u97f3\u4e50\u4eba", "play_counts": null}<font color="red">**exa**</font>1499750991.01634

##### 切分出json格式文件
如上我们是以字符exa分开每个<font color="red">数据库中的字段</font>，需要做的操作如下

使用sed替换掉<font color="red">exa</font>前后的内容，只留下中间的内容
```
sed -i s"/.*exa{/{"/g res.json

sed -i s"/}exa.*/}"/g res.json
```
得到的数据如下
```
{"comment_counts": null, "album_counts": null, "update_time": null, "site_name": "wangyiyun_artist", "fans_counts": "140452", "mv_counts": null, "url": "http://music.163.com/user/home?id=31694264", "song_name": null, "dynamic_counts": "1", "artist_name": "\u71d5\u6c60", "song_counts": null, "style_classify": "\u7f51\u6613\u97f3\u4e50\u4eba", "play_counts": null}
```
可将上面结果粘贴到[<font color="red">**json.cn**</font>](http://json.cn/)查看

其实这就是sqlite3导出数据 + 正则替换，希望能帮助到需要的朋友

##### wget获取数据
除了上面这种直接从result.db中提取数据的方法，你还可以使用pyspider提供的下载结果数据的接口，支持json和csv格式
```
wget http://127.0.0.1:5000/results/dump/wangyiyun_artist.json
```
在指定了账号密码情况下，需要添加http验证
```
wget --http-user=tingyun --http-passwd=tingyun http://127.0.0.1:5000/results/dump/wangyiyun_artist.json
```
<font color="red">注: 但千万注意，在提取的数据量达到一定量级（我在wget一份五百万数据时卡死，只能重启pyspider），会导致整个webui崩溃，推荐第一种方法</font>
#### age和every的解释
```
@every(minutes=24 * 60)
def on_start(self):
    self.crawl('http://www.example.org/', callback=self.index_page)

@config(age=10 * 24 * 60 * 60)
def index_page(self):
    .....
```
every是表明：这个on_start函数隔多少时间执行一次

age：当every < age 时，它即便是重新执行，index_page也会忽略这个时间内来自on_start的url。直到10天之后才会重新启动（处理传递过来的url，重启有效）

### 总结
本文介绍了pyspider的去重，数据提取，单机组件多开，age和every调度概念。但都只是简单地解决本人所遇到的问题，关于进一步的理解，还有待博主阅读pyspider的相关源码后再次分享。更常提起的如send_message和on_message，fetcher架构等等，暂时不敢妄自理解，需要真正看到源码才能明白其实现原理

未完待续....



