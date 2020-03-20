---
title: sphinx初识
date: 2017-04-11 20:17:23
tags: [sphinx, 搜索引擎]
categories: sphinx
---
## 本文主要介绍Sphinx，并进行安装和简单使用
<!-- more -->

### 全文检索
是指以文档的<font color="red">**全部文本信息**</font>作为检索对象的一种信息检索技术。检索的对象有可能是文章的标题，或者作者，或者摘要,内容等

### Sphinx简介
Sphinx是一个基于SQL的全文检索引擎，可以结合MySQL，postgreSQL做全文搜索。能提供比数据库本身更专业的搜索功能，使得应用程序更容易实现专业化的全文检索。

Sphinx特别为一些脚本语言设计搜索API接口，如PHP, <font color="black">**Python**</font>, Perl, Ruby....同时也为MySQL设计了一个存储引擎插件

### Sphinx特性
```
高速索引	10MB/s
高速搜索	2~4G的文件中平均查询速度不到0.1s
高可用性	单CPU上最大可支持100GB的文本，100M的文档

提供良好的相关性排名
支持分布式搜索
提供文档摘要生成
提供从MySQL内部的插件式存储引擎上搜索
支持布尔，短语，和近义词查询
支持每个文档多个全文搜索域（默认最大32个）
支持每个文档多属性
支持断词
支持单字节编码与utf-8编码

注:
支持MySQL（MyISAM和InnoDB表都支持）
支持PostgreSQL
```
### 安装
参考sphinx wiki,deb文件安装即可. [<font color="red">**点此下载**</font>](http://sphinxsearch.com/downloads/)
```
dpkg -i sphinxsearch_2.2.11-release-1-xenial_amd64.deb
```
到这里sphinx安装完成，我们需要使用<font color="black">**sphinx-quickstart**</font>来完成我们的初始化配置。
其中会要求你回答很多的问题，比如根目录的位置，采用什么文本格式....但大部分都选择默认即可，不需要的扩展功能先选择N即可.
这个我后来发现并不是我们需要的东西，这个sphinx-quickstart是基于sphinx的一个文档管理生成工具，之后再去了解。

### 配置Sphinx
找到**/etc/sphinxsearch/sphinx.conf**这个文件，直接对其进行编辑即可

使用vi进入文件，总体配置大致能看到如下这个结构
```
source 源名称1{
	 …
	}
index 索引名称1{
	 source=源名称1
	 …
	}

source 源名称2{
	 …
	}
index 索引名称2{
	 source = 源名称2
	 …
	}

indexer{
	 …
	}
searchd{
	 …
	}
```
从结构上我们可以看出来，sphinx支持多个索引与数据源，只需要你在配置文件中一一对应好即可。不同的索引与数据源可以应用到不同表或不同应用文件的全文搜索。

我们根据这个格式来配置一份自己的索引和数据源,命名为tingyun
```
source tingyun{
		type 			= mysql
		
		sql_host 		= localhost
		sql_user 		= root		#账号
		sql_pass 		= xxxxxx	#密码
		sql_db 			= test		#数据库
		sql_port		= 3306 # optional, default is 3306
		sql_query_pre		=  SET NAMES utf8

		sql_query 		=  SELECT * FROM yourtablename	#sql语句
		#sql_query 		= SELECT * FROM yourtablename 
		sql_attr_uint		= CATALOGID
		sql_attr_uint		= EDITUSERID
		sql_attr_uint 		= HITS
		sql_attr_timestamp 	= ADDTIME
		
		sql_query_post  	=
		sql_ranged_throttle	= 0
		#sql_query_info 	= SELECT * FROM a.eht_news_articles WHERE ARTICLESID=$id
		}
index tingyun_index{
		source 			= tingyun
		path 			= /var/lib/sphinxsearch/data/tingyun_index
		charset_type 		= utf-8
		ngram_len 			= 1
		ngram_chars 		= U+3000..U+2FA1F
		}
indexer{
		mem_limit 		= 128M
		}

searchd{
		listen    		= 9312
		listen         		= 9306:mysql41
		log			= /var/log/sphinxsearch/searchd.log
		query_log		= /var/log/sphinxsearch/query.log
		read_timeout		= 5
		client_timeout		= 300
		max_children  		= 30
		seamless_rotate     	= 1
		preopen_indexes     	= 1
		unlink_old      	= 1
		workers         	= threads
		pid_file   		= /var/run/sphinxsearch/searchd.pid
		max_matches   		= 1000
		seamless_rotate 	= 1
		binlog_path      	= /var/lib/sphinxsearch/data
		}

```

配置完了之后，建立索引，在此之前，我记下了一些用得到的路径
```
/var/lib/sphinxsearch/data/

/var/log/sphinxsearch/searchd.log

/var/log/sphinxsearch/query.log

/var/run/sphinxsearch/searchd.pid
```

#### 建立索引
indexer 会默认去找/etc/sphinxsearch/sphinx.conf，在你没有使用-config "file-path"指定使用某个config文件的时候
```
hello#indexer tingyun_index
Sphinx 2.2.11-id64-release (95ae9a6)
Copyright (c) 2001-2016, Andrew Aksyonoff
Copyright (c) 2008-2016, Sphinx Technologies Inc (http://sphinxsearch.com)

using config file '/etc/sphinxsearch/sphinx.conf'...
WARNING: key 'charset_type' was permanently removed from Sphinx configuration. Refer to documentation for details.
indexing index 'tingyun_index'...
WARNING: attribute 'catalogid' not found - IGNORING
WARNING: attribute 'edituserid' not found - IGNORING
WARNING: attribute 'hits' not found - IGNORING
WARNING: attribute 'addtime' not found - IGNORING
WARNING: Attribute count is 0: switching to none docinfo
WARNING: source tingyun: skipped 11329 document(s) with zero/NULL ids
collected 866 docs, 0.1 MB
sorted 0.0 Mhits, 100.0% done
total 866 docs, 64852 bytes
total 0.012 sec, 5160499 bytes/sec, 68910.63 docs/sec
total 3 reads, 0.000 sec, 10.7 kb/call avg, 0.0 msec/call avg
total 9 writes, 0.000 sec, 5.7 kb/call avg, 0.0 msec/call avg
```
这时候我们能看见/var/lib/sphinxsearch/data/这个目录下出现了一下.sp*结尾的文件，这就是我们建立的索引文件
```
ls /var/lib/sphinxsearch/data/
tingyun_index.spa  tingyun_index.spe  tingyun_index.spi  tingyun_index.spm  tingyun_index.sps
tingyun_index.spd  tingyun_index.sph  tingyun_index.spk  tingyun_index.spp  tingyun_index.tmps
```

#### 启动索引服务
同上，searchd也是先去找默认的sphinx.conf文件.
```
hello#searchd 
Sphinx 2.2.11-id64-release (95ae9a6)
Copyright (c) 2001-2016, Andrew Aksyonoff
Copyright (c) 2008-2016, Sphinx Technologies Inc (http://sphinxsearch.com)

using config file '/etc/sphinxsearch/sphinx.conf'...
WARNING: key 'charset_type' was permanently removed from Sphinx configuration. Refer to documentation for details.
listening on all interfaces, port=9312
listening on all interfaces, port=9306
precaching index 'tingyun_index'
precaching index 'test1'
WARNING: index 'test1': preload: failed to open /var/lib/sphinxsearch/data/test1.sph: No such file or directory; NOT SERVING
precaching index 'test1stemmed'
WARNING: index 'test1stemmed': preload: failed to open /var/lib/sphinxsearch/data/test1stemmed.sph: No such file or directory; NOT SERVING
WARNING: multiple addresses found for 'localhost', using the first one (ip=127.0.0.1)
precaching index 'rt'
precached 4 indexes in 0.005 sec
```

### python调用索引检索mysql中数据
先提起一个坑:就是在建立索引的时候需要目标数据是带有唯一id值的,这里我设定了一个自增主键,用那个主键作为了一个唯一索引值.千万记得:<font color="red">**如果没有主键,那么无法使用索引**</font>

这时候我们的索引创建已经完成,接下来我们使用python脚本试着去调用索引检索mysql中的数据
```bash
#查到sphinxapi.py的路径,并将路径下所有的.py文件拷贝出来,其中的调用api可以参考
updatedb 
locate sphinxapi.py
```
这里找了一个简单的脚本match了一下关键词([源代码出处](https://www.u3v3.com/ar/1264))
```python
#!coding:utf8
from sphinxapi import *
import sys
import pymysql

con = pymysql.connect(host='127.0.0.1', port=9306, user="yourname", passwd="yourpassword", db="yourdb")
with con.cursor(pymysql.cursors.DictCursor) as cur:
	cur.execute("select * from tingyun_index where match('2006-04-14') limit 3")
	print(cur.fetchall())
```
这句话的功能是查询指定db中,的2006-04-14关键词的所有记录,返回目标的索引id值,然后我们能根据这些id值去库中直接拿取对应数据

到这里算是完成了sphinx的安装到简单使用,下一步考虑使用sphinx对mongodb的库建立索引,然后通过调用python脚本从mongo检索出对应的数据,最近两天在屯数据(但几个歌曲平台的数据都是千万级别的,就算我满负载去跑估计也得话费很长时间,试着用用公司服务器),还有感觉scrapy单机单进程抓取简直难以忍受的慢,20M的带宽只用到了200kb/s.....明天会想想怎么提高抓取效率









