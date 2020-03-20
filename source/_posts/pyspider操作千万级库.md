---
title: pyspider操作千万级库
date: 2017-10-20 23:47:30
tags: [pyspider , mysql]
categories: [pyspider]
---
### 本文叙述pyspider在对接量级较大库的策略
<!-- more -->
### 背景
　　最近这这几天依旧是在搞我的爬虫，看看图像识别这一块的东西，没啥需求的时候就在git上瞎逛，发现什么好看的项目就拿过来用用，比如之前遇到过的haproxy和最近这几天看到的netdata，其实都是在需要做相关的事情才会去注意这些比较优秀的开源项目
　　但是晴天霹雳，突然接了一单，而且据说量还不小.....三个平台，种子数据上千万，要抓取的内容大致估计上亿条数据，花费时间我就没来得及具体去算了
　　这几个月所有的抓取任务以及都移到pyspider上了，全部大约有100个站点左右，大部分都只是定时即可，一般按月例行。我开始也没太在意，就匆匆把抓取逻辑这些写完了，准备去接另外一帮人给的mysql时，感觉有点不太对劲......
　　
　　按照之前的任务来说，在on_start()中启动脚本，我读取的或一些小文件，或一些excel，或直接去扫描对方的站点即可。但是这次的需求是需要抓完其全部库里面的数据，按照每条给出的数据去检索，那我们必然需要读完一次全表，看了看量，他们先导了一部分进去，大概450w....当时我的手心里应该是有点汗的，并且面色紧张地问：一次性给这么多吗？
　　
　　如果是需要pyspider正常的流程去执行，那必然是会<font color="purple">**在on_strat()时任务执行超时，可能只读取出几万条或十几万条数据就会被破终止**</font>，然后执行index_page()，由于这个超时时间限制，且self.crawl()之后程序不是异步的，会暂时阻塞在on_start()这一步，若是异步的，可能情况会好点，但也可能会因为mysql读库太快，导致中间沉积大量任务
　　所以我们需要其他的思路去解决这个问题
### on_finished(self)
　　pyspider看了一部分代码，但大多只是scheduler以及mysql的代码，好多比较巧妙的功能其实都没有看到，比如，作者在文档中提到：可以直接重写on_result(self,response)这个函数重新定义数据落地。我又想想有一个on_start(self)，还有on_result()，我就感觉作者写的组件是不是都是分开的，能够被重载的，我就想试试看能不能在一个任务结束的时候做一些操作，即这个：on_finished()
　　
　　在pyspider项目中寻找字段on_finished，找打如下
```python
def on_finished(self, response, task):
    """
    Triggered when all tasks in task queue finished.
    http://docs.pyspider.org/en/latest/About-Projects/#on_finished-callback
    """
    pass
```
```text
You can override `on_finished` method in the project, the method would be triggered when the task_queue goes  
 to 0.

Example 1: When you start a project to crawl a website with 100 pages, the `on_finished` callback will be  
 fired when 100 pages are successfully crawled or failed after retries.

Example 2: A project with `auto_recrawl` tasks will **NEVER** trigger the `on_finished` callback, because  
 time queue will never become 0 when there are auto_recrawl tasks in it.

Example 3: A project with `@every` decorated method will trigger the `on_finished` callback every time when  
 the newly submitted tasks are finished.

```
　　以上这几句话翻译如下
```text
您可以在项目中重写`on_finished`方法，当task_queue变为0时，该方法将被触发。

示例1：当您启动一个项目来抓取100页的网站时，在重试后成功抓取100页或失败后，“on_finished”回调将被触发。

示例2：具有`auto_recrawl`任务的项目将不会**触发`on_finished`回调，因为当其中有auto_recrawl任务时，时间队列永远不会变为0。

示例3：每次新提交的任务完成时，带有@every装饰方法的项目将触发“on_finished”回调。
```
　　于是我尝试着<font color="red">**在on_finished(self,response)中去执行我们的操作，比如写文件，比如打log，比如回写数据库，发现我们可以在其中执行任何我们操作，接下来我们结合on_finished()去解决读库的问题**</font>
### 定义刷库规则
　　首先，我们在种子库中有一定数据量，并且有一个唯一id值，那么我们在表中多加一个字段<font color="red">**is_crawled，标识该id是否被抓取**</font>，为了保险，再加一个<font color="red">**crawl_time记录其是什么时间被抓取入库的**</font>

　　那么有了这两者前提，可以在我们原始的抓取逻辑中修改代码了
```python
from pyspider.libs.base_handler import *
import pymysql
import datetime

class Handler(BaseHandler):
    crawl_config = {
    }
    #要回写的一批id
    batch_ids = []

    #@every(minutes=24 * 60)
    def on_start(self):
        #填充要读取的数据库信息
        conn = pymysql.connect(host="ip",
                           port=3306,
                           user="user",
                           password="pwd",
                           db="db_name",
                           charset='utf8'
                           )
        cursor = pymysql.cursors.SSCursor(conn)
        #取出没有被抓取过的结果，一次100条
        sql = "select * from seed_table where is_crawled=0 limit 100"
        cursor.execute(sql)
        print sql
        while cursor:
            try:
                row = cursor.fetchone()
                #提取需要的字段，如检索关键词类似的
                name = row[1]
                age = row[2]
                #........
                
                #记录丢入任务的id值，为seed_table表的主键
                id = row[0]
                self.batch_ids.append(id)
                
            except Exception,e:
                break
    
            url =  "http://www.xxxx.com/search_spi/?name=%s&age=%s....."%(name,age)
            self.crawl('', callback=self.index_page,update_force=True)

    @config(age=10 * 24 * 60 * 60)
    def index_page(self, response):
        for each in response.doc('a[href^="http"]').items():
            self.crawl(each.attr.href, callback=self.detail_page,update_force=True)

    @config(priority=2)
    def detail_page(self, response):
        return {
            "url": response.url,
            "title": response.doc('title').text(),
        }
    
    def on_finished(self,response):
        conn,cursor = db_connetionDict("ip","user","pwd","db")
        for id in self.batch_ids:
            crawl_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            sql = "update seed_table set is_crawled=1 and crawl_time=%s where id=%s "%("'"+crawl_time+"'",id)
            cursor.execute(sql)
        conn.commit()
        conn.close()
        #回写完成，最后一步，重新调用self.on_start(),重新去取得库中前100条没有被抓取过的歌曲
        self.on_start()
        

def db_connetionDict(ip,user,pwd,db):
    conn = pymysql.connect(host=ip,
                           port=3306,
                           user=user,
                           password=pwd,
                           db=db,
                           charset='utf8'
                           )
    cursor = pymysql.cursors.DictCursor(conn)
    return conn,cursor

```
　　每次<font color="red">**在on_finished()时调用on_start()，其实际是执行一个新的任务，所以self.batch_ids也会被重新赋值为[]，抓取新的id，然后回写，重复这个逻辑**</font>

　　按照如上的逻辑，即可以不断循环去获取seed_table中的没有被抓过的前100条，直到所有数据都被抓过一遍，这个程序就一直开着，不用管了，估计也得上月份才能慢慢完成

　　到这里，我们针对大库的处理方法就结束了
### 新的问题，关于抓取状态的描述
#### 问题描述
　　在上面的例子我们仅仅是抓取单纯一个站点，所以抓取完了，就可以将seed_table中的源数据的is_crawled置为1，但是如果不是一个平台呢？

　　如果是三个平台同时在运行，他们都是取出seed_table中is_crawled为0的数据去抓取，但假设平台1抓过了某100条，将这些记录全部都置成了1，那么其余的两个平台就无法取出这些已经被平台1抓过的数据
#### 解决方法
　　由于需要抓取的平台是三个，并且我们只有一个字段标识这三个平台的抓取状态，我们很容易想到了位运算，1表示已抓，0表示初始状态

```text
1 --- 001 --- 平台1

2 --- 010 --- 平台2

4 --- 100 --- 平台3
```
　　每次，我们取数据的那一台语句应该对应地更改成
```python
#平台1
sql = "select * from seed_table where is_crawled&1!=1 limit 100"

#平台2
sql = "select * from seed_table where is_crawled&1!=2 limit 100"

#平台3
sql = "select * from seed_table where is_crawled&1!=4 limit 100"
```
　　按位与的话，若平台1：数a & 1（001） != 1 表明a的第一位必然不是1，同理平台2和平台3也是一样

　　之后平台扩充的话，只需要更改新平台，老平台的抓取代码也不需要改变

　　最后的回写操作也要稍微更改下
```python
#平台1
sql = "update seed_table set is_crawled=is_crawled | 1 and crawl_time=%s where id=%s "%("'"+crawl_time+"'",id)

#平台2
sql = "update seed_table set is_crawled=is_crawled | 2 and crawl_time=%s where id=%s "%("'"+crawl_time+"'",id)

#平台3
sql = "update seed_table set is_crawled=is_crawled | 4 and crawl_time=%s where id=%s "%("'"+crawl_time+"'",id)
```
　　分别在不同的位上或上一个1，也就相当于对那一位进行了将0转换成1的过程
### End
最近一段时间都是和mysql打交道，单个库的存储量也早就达到了好几千万，即便是建了索引，也能明显感觉到有点慢了，后续再测试下其他一些数据库的性能，有可能的话换换看es
有什么错误还请提出，给我发邮件或评论，不尽感激~~

### 2017-11-12更新
　　hello，过完光棍节回来调bug啦~~
  
　　以上的尝试在经过博主的一段时间观察，发现其中有点不对劲的地方，接着上面提到的内容，我们不断循环去获取seed_table中的没有被抓过的前100条，并且在on_finished()中将这100条在数据库中更改状态，再调用on_start()
    
　　这看起来像是一个设想很好的过程，但是在实际的抓取中，我设定的100个任务会大概率重复执行3~5遍，因为<font color="red">**在on_finished()中我并没有收到那需要被回写的100条id，所以库状态还没有更改，一直重复去取上一次任务的100条**</font>
  
　　更具体请查看[<font color="red">**我在sf中提到的问题**</font>](https://segmentfault.com/q/1010000011797351)

　　且作者也在其中回答了我这个疑问，即<font color="blue">**pyspider脚本的设定是分布式的，所以不保证当前的Handler只有一个运行实例，使用其类间变量的结果是不确定的**</font>
  
　　也提到了，如果想要多个类（脚本）实例间共享一个变量，将其放到redis中或者采用其他策略
　　我能想到的具体方法是在redis中不断更新一个key，<font color="purple">**每次在on_start()中填充进去，到了on_finished()中先回写这些id，完成之后再清空其value**</font>，不断重复这个过程，能达到上述的效果
  
　　但显然我之前的那个想法是个坑，在此道个歉，(逃)
  
  