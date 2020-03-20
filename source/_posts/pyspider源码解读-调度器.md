---
title: pyspider源码解读--调度器
date: 2017-09-03 18:22:33
tags: [pyspider , scheduler]
categories: [pyspider]
---
## 本文介绍pyspider的调度流程
<!-- more -->

### 背景
从此篇开始后续会逐步写一些关于pyspider的源码分析的代码，因为之前一段时间都在看其代码，最一开始是从webui中的py文件开始看起的，之后又看完了mysql中的一些封装，自己加上了两个原生的 mysql 库，用来做其他管理，但是其中最核心的部分，大抵是scheduler.py这一部分，所以我首先将这一部分描述清楚，作备忘录

在阅读本文之前最好需要对pyspider的基本使用有简单了解，比如项目的几种状态切换...etc
### scheduler.py
首先，我们从pyspider的根目录下找到<font color="red">/pyspider/scheduler/scheduler.py</font>
其中定义了四个类：
```python
class Project(object)

class Scheduler(object)

class OneScheduler(Scheduler)

class ThreadBaseScheduler(Scheduler)
```
这四个类的作用分别如下
#### Project  
单个项目的Paused状态切换即是由这个类实例化的对象来完成，其中的方法有---paused()，update(project_info)

#### Scheduler 
整体的调度过程，包括从入库，读库，对task的操作（主要是各个队列之间的get和put，以及task执行包的封装），状态的切换

#### OneScheduler 
debug中用到的类，其继承自Scheduler，不同的是，它不会将需要抓取的task丢入到一个消费者队列中，而是会直接调用一个process立刻去执行fetch（其实现在send_task这一函数）

#### ThreadBaseScheduler 
这个类用到的地方很少，在pyspider/libs/bench.py中用到过，作压力测试

**<font color="red">这里我们主要看Scheduler类</font>**
### Scheduler(object)
关于从哪儿开始看起，其实这个类中一大堆的方法以及很多的变量，我首先一步是跳过这些，先看所有函数的名字以及其中的注释看一边，首先看到的是run以及run_once
对了，关于变量，在具体看某一个函数的时候，可以再去查询这个变量第一次出现的位置，结合函数的作用就能大致明白这个变量的功用了
<font color="red">**注：这里我不再赘述如何去看代码，只是将看懂的东西作一个整理**</font>
```python
def run_once(self):
        '''comsume queues and feed tasks to fetcher, once'''

        self._update_projects()
	self._check_task_done()
        self._check_request()
        while self._check_cronjob():
            pass
        self._check_select()
        self._check_delete()
        self._try_dump_cnt()

```
#### self._update_projects()
更新project的状态，并且回显到webui上 （这个操作经由几步调用，其会去读所有项目的库，并且load到各自的task_queue中）
#### self._check_task_done()
去不断取出scheduler的status_queue优先级最高的任务，并检测其状态
#### self._check_request()
其会优先去取_postpone_request中的延迟task，因为这些极有可能是上次版本运行改变遗留下的一些认为有（比如某个任务正在跑，我们手动stop了它，然后修改了脚本，再重新启动它），将其发送给on_request

然后去获取newtask_queue中的任务，并且不断将这些任务交给on_request, on_request会作一些判断，然后将其put到各自project的task_queue中
#### 总结如上三个方法
**<font color="red">上面的操作无非都是向各个项目的 task_queue中填充内容，从数据库读取 / 从新产生 的任务中生成</font>**
#### self._check_select()
这个函数会优先从缓冲队列中读取任务（当任务太多的时候，会将多余任务放到缓冲队列中），然后正常遍历所有的project，并且将其中的task_queue取出（**<font color="red">在此之前，每个project首先会更新各自的task_queue的优先级队列：两个，一个time，一个process</font>**），并且使用自定义方法get()取得优先级最高的task（这个获取是从proicess优先级队列中取出的）

time优先级 和 process优先级 队列 的关系是：process是真正被取出去执行的任务，time是生成process的一个条件，也就是从time中取时间优先级最高的不断添加到process中

更新完了之后，将获取到的taskid按顺序保存，传递给_load_put_task()函数，经由其从数据库中(根据taskid)读信息，再传递给on_select_task()方法

**<font color="red">on_select_task()这个函数是给每个taskid填充完整的信息，最后添加到所在project的active队列中，表明其正在被调度</font>**

最后的最后，再由send_task()方法传递到 out_queue队列中（如果out_queue满了，会放到缓冲deque中）
#### 其余两个方法
self._check_delete()
self._try_dump_cnt()
前者是检测是否有到达约定时间需要删除的项目，后者是定时回显webui页面上的任务数目状态(60s一次)
#### run_once
**<font color="red">这个函数的功能就是将需要被调度的taskid，经过一系列中间转换，带上了一些优先级，最后全部丢入到调度器类本身的一个out_queue队列中，这个队列作为一个生产者，供给fetch消费</font>**

### 详细流程,队列间传递消息
**<font color="blue">图1</font>**
![示例图1](/pyspider源码解读-调度器/1.png)

大致的调度情况如上，其中的queue指的是作者在其中自己封装实现的一些优先级队列（其实现在**<font color="red">/pyspider/scheduler/task_queue.py</font>**），deque一般都是被用作缓冲队列

### End
这一篇说是读源码，可实际上并没有多少源码，并不是作者不想贴出代码一行行解释，但是篇幅有点太多，这一篇首先把大致的脉络理清楚，具体的代码实现，我会放到后续的篇幅中分成多部分解释

如果有存在错误的地方，还希望大家指出，可能有理解错误的地方，见谅

