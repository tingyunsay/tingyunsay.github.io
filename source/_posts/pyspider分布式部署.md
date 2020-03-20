---
title: pyspider分布式部署
date: 2017-09-08 23:21:10
tags: [pyspider , 分布式]
categories: [pyspider]
---
## 本文介绍pyspider的分布式部署
<!-- more -->

### 前言
关于pyspider的分布式搭建，网上已经存在一个比较好的版本(即简书上的这篇[**<font color="red">centos7分布式部署pyspider</font>**](http://www.jianshu.com/p/8eb248697475)),博主搭建也主要是参照这篇文章，已经讲解得相当详细了，所以在搭建方面本文不太多作文字，主要是记录下在搭建过程中可能需要注意的问题
**<font color="red">环境</font>**
```shell
Centos6.x
python2.6.6
```
### 搭建流程
#### 配置好config.json文件
```python
{
      "taskdb": "mysql+taskdb://user:pass@192.168.218.10:3306/taskdb",
      "projectdb": "mysql+projectdb://user:pass@192.168.218.10:3306/projectdb",
      "resultdb": "mysql+resultdb://user:pass@192.168.218.10:3306/resultdb",
      "message_queue": "redis://192.168.218.10:6379/db",
      "phantomjs-proxy":"192.168.218.10:24444",
      "webui":{
                  "host":"192.168.218.10",
                  "port":"4999",
                  "scheduler-rpc":"http://192.168.218.101:5001",
                  "fetcher-rpc":"http://192.168.218.102:5002"
      },
      "scheduler":{
                  "xmlrpc":true,
                  "xmlrpc-host":"0.0.0.0",
                  "xmlrpc-port":"5001"
      },
      "fetcher":{
                  "xmlrpc":true,
                  "xmlrpc-host":"0.0.0.0",
                  "xmlrpc-port":"5002"
      }
    }
```
这里提及一下，其中各个key所代表的意思
1. 其中db相关的字段指明了使用的库文件的目录 ， 在项目启动的时候其会自动创建3个database ， 分别是 taskdb ， projectdb ， resultdb
2. message_queue 指定了所使用的消息队列，这里我们是在 218.10:6379 上的redis
3. phantomjs-proxy 指定了使用的渲染工具地址，有必要还需要限定内存大小，以避免内存泄露
4. webui 即是我们使用的地址，我这里只设定了一个webui ， 可以想下面的模块一样，使用 : “host”:"0.0.0.0" ，可以在多台机器上启动相同的管理页面
5. scheduler:  必须只有一个，启动多个会报错，由于其需要大量操作数据库（相关的task操作），最好部署在一台性能比较高的机器上
6. fetcher : 框架使用的是tornado的异步网路io事件处理，所以不会阻塞在fetcher这里，一般一个就行了
7. processor / result_worker : 不需要在配置文件中指定，其只需要知道webui中设定的 schedule-rpc 和 fetcher-rpc 的地址即可，不需要指定什么端口，它们只需要听从调度即可

#### 使用supervisor管理进程
在每台机器上创建一个 绝对路径相同的目录(**<font color="purple">用来存放每个进程运行过程中产生的日志</font>**)，如：mkdir /home/work/supervisor/ (这样就不需要更改stdout_logfile的路径了)， 用来记录程序运行的日志文件
supervisor进程的配置文件在 /etc/supervisord.conf ，我们直接编辑这个文件即可
```python
[program:webui]
command = /usr/bin/python /home/work/distri_pyspider/run.py -c /home/work/distri_pyspider/config.json webui
directory = /home/work/liaohong/distri_pyspider/spider_platform
user = work
autostart = true
autorestart = true
startsecs = 3
redirect_stderr = true
stdout_logfile_maxbytes = 500MB
stdout_logfile_backups = 10
stdout_logfile = /home/work//supervisor/webui.log
```
如上代码只包含了webui的配置格式，其他的如fetcher，scheduler其实都很一样

需要注意的是 command 最好全部使用绝对路径，directory表示在哪个目录下执行command，最后一条是日志信息，这里我们给它取名 webui.log （**<font color="purple">我们上面提到的最好使用类似的路径，好处是我们在每台机器上部署的时候，把代码一粘贴，路径部分就不需要再改动了，只需要给日志改个名字，如：webui1.log ;  webui2.log .........</font>**）

按照这个格式继续添加processor和其他等等（当前机器需要运行什么模块就将对应模块的配置写入到 /etc/supervisord.conf 中）
如processor，我们这里启动一个命名为 processor1
```python
[program:processor1]
command = /usr/bin/python /home/work/distri_pyspider/run.py -c /home/work/distri_pyspider/config.json processor
directory = /home/work/liaohong/distri_pyspider/spider_platform
user = work
autostart = true
autorestart = true
startsecs = 3
redirect_stderr = true
stdout_logfile_maxbytes = 500MB
stdout_logfile_backups = 10
stdout_logfile = /home/work/supervisor/processor1.log
```
supervisord.conf文件写好之后，我们就需要启动它了：
```shell 
supervisord -c /etc/supervisord.conf

supervisorctl reload

supervisorctl status            #查看部署的进程是不是都正常在运行
```
![图一](/pyspider分布式部署/1.png)
如上图所示表示已经正常启动了
之后，我们再看看我们的日志文件是不是已经存在：
![图二](/pyspider分布式部署/2.png)
文件也创建成功，那么表明这台机器需要创建的任务已经完成
最后，按照同样的方法去另外几台机器上部署即可

**<font color="purple">大致的部署方法不外乎如上两步操作，接下来介绍部署过程中遇到的一些问题以及解决方法</font>**
### Problem List
#### webui无法访问
在分布式之前，必然是保证单机正常运行，这里的正常运行指的是所有的功能完备，你需要看到webui，能够执行之后的相关操作，但其实经常会有人遇到这样的问题，即出现了如下图显示的(貌似)正常运行图
![图三](/pyspider分布式部署/3.png)
但是在浏览器上却通常是如下的结果:
```shell
Empty reply from server
```
这时候想看看是不是浏览器出了问题，我们又用到了如下的命令：
```python
curl 192.168.xxx.xxx

#同样返回
curl: (52) Empty reply from server
```
也就是说这个服务并不是想图一中说的，正常启动了，而是**<font color="purple">出于某种原因，无法给你响应请求</font>**
我们再看看是不是端口被限制（防火墙）的问题，使用nz命令
```shell
nc -z -w 10 192.168.xxx.xxx 5000
#默认以tcp的方式请求，-u表示udp，这里我们默认的tcp即可
#成功会输出成功信息
Connection to 192.168.xxx.xxx 5000 port [udp/domain] succeeded!

#若没有输出任何信息，执行下面这行
echo $?

#若输出1，表示端口开启；输出0，表示端口关闭
1
```
也就是说，这里我们的端口是成功的

总结如上的测试，我们的pyspider服务必然是启动了的，但是在通信的时候，出了一些差错，导致无法给予你正常的服务，并且我们可以观察到，几次请求之后我们的终端并没有出现任何响应的动作，那就说明你的请求压根没有被pyspider正常接受

**<font color="red">解决方法</font>**
将centos自带的python2.6.6替换成2.7版本，替换过程请查看这篇[<font color="purple">**python2.6.6更换2.7**</font>](http://tingyun.site/2017/09/09/python2-6-6%E6%9B%B4%E6%8D%A22-7/)，这里我使用的是python2.7.11
之后重新使用新的pip安装pyspider即可，webui正常访问

#### supervisor
```
yum install supervisor

pip install supervisor
```
在部署过程中可能还会遇到supervisor部署的相关问题，如下两个常见的报错
```shell
unix:///var/tmp/supervisor.sock refused connection

unix:///var/tmp/supervisor.sock not exists
```
**<font color="red">解决方法</font>**
```shell
rm /var/tmp/supervisor.sock

vi /etc/supervisord.conf

#添加如下4行
[unix_http_server]
file = /var/tmp/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

#以新文件启动supervisord
supervisord -c /etc/supervisord.conf

supervisorctl reload

supervisorctl status
```
在服务器上操作的话，还需要注意的有权限，删除/var中的文件需要root权限，在删除完之后注意退出，使用work去执行或编辑其他的任务，这样不会导致某个操作遇到Permission denied错误
