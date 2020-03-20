---
title: mysql查询优化
date: 2017-10-01 01:23:24
tags: [mysql]
categories: database
---
## 本文介绍mysql基础的一些优化措施
<!-- more -->
### 背景
mysql  量约100w
本文是在mysql库量不断增加的情况下，某一次在前端页面查询发现慢的不能忍了（花了5分钟+，还总是导致网页504 ╥﹏╥...）,开始的解决方法为主键建立索引，在select count操作能在1s内完成

但这种事情最好根治，不能说等某个库到达一个量级再去刷库，这不是正常的解决方法，应该在开始的时候就建立好相关的索引文件，以及需要的查询优化。所以后续在网上查阅了相关资料和博客，记录在此
### 建表时优化
#### 创建普通索引
以下例子为 普通字段 id 创建了索引
```mysql
create table tingyun(
     id int,
     name varchar(100),
     index(id)
);
```
在使用 show create table `table_name` 的时候，能看到KEY `id` (`id`)  表明这个字段已经有了索引

并且在使用
```mysql
explain select * from table_name where id = 1;
```
```mysql
MariaDB [resultdb2]> explain select * from music_qq_copyright where id = 1;
+------+-------------+--------------------+-------+---------------+------+---------+-------+------+-------+
| id | select_type |   table   |  type  | possible_keys | key | key_len | ref | rows | Extra |
+------+-------------+--------------------+-------+---------------+------+---------+-------+------+-------+
| 1 | SIMPLE | music_qq_copyright | const |     id     |  id  |    4    | const | 1 | |
+------+-------------+--------------------+-------+---------------+------+---------+-------+------+-------+
```
其中 possible_keys 和 key的值都为id（索引字段的名字），则id索引已经存在并且查询中已经使用了索引

#### 创建唯一性索引
你也可以为你创建的索引起一个其他的名字：index_name
```mysql
create table tingyun(
     id int,
     name varchar(100),
     unique index index_name(id)
);
```
#### 创建多列索引
```mysql
create table tingyun(
     id int,
     name varchar(100),
     sex char(10),
     index index_name(id,name)
);
```
和创建单列索引类似，在( )中添加多个字段名即可
注：<font color="red">**以上中我略去了 全文索引 以及 空间索引 的创建，那又是另外的应用了，这里我不作说明**</font>
### 为已经存在的表建立索引
这种情况是你在建表的时候并没有建立索引或者说你后期的查询需要建立组合索引来加速，这时候必须更改表结构，以及每条记录的结构，也就是每次更改得刷一遍库
#### 添加主键索引
```
alter table `table_name` add primary key (`字段名`)
```
#### 添加唯一索引
```
alter table `table_name` add unique (`字段名`)
```
#### 添加普通索引
```
alter table `table_name` add index index_name(`字段名`)
```
#### 添加全文索引
```
alter table `table_name` add fulltext index_name(`字段名`)
```
#### 添加多列索引(组合索引)
在你需要多种查询条件的时候如where and / order by，可以通过建立这种索引的方式提高查询速度，将可能用到的字段添加到组合索引中
```
alter table `table_name` add index index_name(`字段名1`,`字段名2`,`字段名3`)
```
注：<font color="purple">**以上3,4,5中的index_name 默认可以不写，可以自己取名索引为某个index_name**</font>
### 速度对比
本文记录的是pyspider的result页面的打开速度，由于一开始也是在pyspider的页面上遇到这个问题，所以这里我们会更改pyspider一点源代码来解决这个问题

#### 分页查询
一：xiami_mv  ,  8万条数据 ， 查询翻页的时候，order by updatetime的时间
给updatetime加上索引后的效果
```
未加之前:
628ms / 459ms  /  1.43s / 389ms /  652ms  /  594ms  /  639ms  / 805ms /  1.01s

加完后：
573ms /  302ms /  270ms /  254ms /  244ms  / 283ms  /  278ms  /  620ms  /  362ms
```
查询完全一样的数据，能看到有明显的变化，速度快了一倍左右

二：wangyiyun_music , 60万数据，进行同样查询翻页的操作
```
#未加索引
4.06s  /  4.11s / 4.11s  /  5.31s /  4.85s  / 5.37s  /  5.29s  /  4.39s /  4.99s

#加完后
486ms  /  875ms  /  597ms  /  1.23s  /  960ms  /  862ms  /  828ms  /  1.02s  /  725ms
```
这个效果更加明显了
#### 直接查库
这里我开始并没有为主键建立索引，而是为整个表添加了一个唯一自增id值，mysql内置有个查询优化器，在select count(*)的时候会去找所有字段中长度最短的那个键，我之前的主键是一个16位的md5值，其他值都是更大的文本，其必然会找到这个新建立的id值进行查询
**查库消耗时间 qq_mv 87w**
```
select count(*) from qq_mv;

     5 min 5.95 sec
```

**刷表消耗时间**
```
alter table qq_mv add `id` bigint(20) not null auto_increment unique key;

Query OK, 871861 rows affected (1 min 44.64 sec)
Records: 871861 Duplicates: 0 Warnings: 0
```

**添加unique 自增键后**
```
select count(*) from qq_mv;

     1 row in set (0.71 sec)
```
#### 修改pyspider的建表语句
在 <font color="red">**pyspider/database/mysql/resultdb.py**</font>
```
    def _create_project(self, project):
        assert re.match(r'^\w+$', project) is not None
        tablename = self._tablename(project)
        if tablename in [x[0] for x in self._execute('show tables')]:
            return
        self._execute('''CREATE TABLE %s (
            `taskid` varchar(64) PRIMARY KEY,
            `url` varchar(1024),
            `result` MEDIUMBLOB,
            `updatetime` double(16, 4),
            INDEX(taskid),
            INDEX(updatetime) 
            ) ENGINE=InnoDB CHARSET=utf8''' % self.escape(tablename))
```
注意到：我为其中的taskid和updatetime字段均建立了索引，前者是在<font color="purple">**count操作时加速**</font>，后者是在<font color="purple">**分页查询时加速**</font>
注：
针对其不同用处添加对应的索引，如果需要添加组合查询，如按url和result模糊查询
```
select ... from ... where url like "%xxx%" and result like "%xxx%" 
```
则建立 INDEX(url,result)

### End
正准备去看《高性能mysql》这本书，会将做的笔记整理放上来

-------------------
