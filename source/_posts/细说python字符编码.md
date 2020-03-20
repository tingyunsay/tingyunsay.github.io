---
title: 细说python字符编码(一)
date: 2017-10-15 01:58:46
tags: [编码,unicode,utf8,ascii]
categories: [python]
---
### 本文介绍python字符编码相关
<!-- more -->
### 背景
今天遇到一个问题：要将unicode转换成ascii
一开始不以为然，觉得不就是一个encode("ascii")就行了嘛，但实上要注意的比我想象的要多得多。因为在实际操作的过程中，总是报出来各种错误，接着去google，去百度，但一片片博文看得自己更加乱，于是想自己整理下，再重新理清楚编码相关的问题
### chardet
开篇先介绍下这个库，我们使用其来进行字符编码的判断
```python
#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import chardet

a = "hello"
b = "你好"
c = "hello 你好"

print chardet.detect(a)
print chardet.detect(b)
print chardet.detect(c)

#>>> {'confidence': 1.0, 'language': '', 'encoding': 'ascii'}
#>>> {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
#>>> {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
```
其中confidence表示判断的准确性（存在不确定性）
需要注意的是：<font color="purple">**chardet.detect()不能检查unicode，只能检查编码格式**</font>（unicode并不是一种编码格式，而是一种编码规则）
### setdefaultencoding
这个函数在上网搜关于python编码问题的回答可能最常见就是它，它的作用到底是什么呢？是不是一个万能的解决方法呢？我们先来看看它是干嘛的
```python
import sys
reload(sys)
sys.setdefaultencoding('utf8')
```
在py文件的头部加上这一句，其作用是：<font color="purple">**指定与其相关的encode和decode函数的默认中间转换编码格式**</font>
这里我们指定其都按照utf8的格式编码；不加之前默认是以ascii的格式编码
```python
#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys

print sys.getdefaultencoding()

#>>> ascii

#我们加上setdefaultencoding，并设定成utf8
import sys
reload(sys)
sys.setdefaultencoding('utf8')

print sys.getdefaultencoding()

#>>> utf8

```
那么输出的这两个ascii 和 utf8 都代表着什么呢？上面我们提到的：和字符串的转换过程有关，继续看
### encode & decode
这两个函数是我们用的最多的字符串编码相关的工具，其作用是将一个字符串编码，或者解码成指定的格式，用法如下
```python
#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import chardet

a = "你好"

print type(a)
print chardet.detect(a.encode())
print chardet.detect(a)


#>>> <type 'str'>
#>>> {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
#>>> {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
```
可以看出来，a.encode()和a是一样的编码，这个encode()过程做了什么呢？
我们假设调用这两个函数的元素为 a ，即a.decode()和a.encode()
#### encode
encode先判断a的类型，<font color="purple">**若是unicode则根据其元素组成直接encode成对应的元素**</font>，若是str类型，是先将a进行一次解码，也就是调用decode()，这个decode默认以环境的defaultencoding作为解码格式（这里我们设定为了utf8），<font color="purple">**解码成了unicode之后**</font>，再根据其底层字符编码编码成对应的字符,那么这整个过程就是
**a.decode("utf8").encode("utf8")**

其目标是生成一个str类型的元素，编码一般我们指定为utf8
#### decode
decode的作用和encode相反，decode也是先判断a的类型，<font color="purple">**若是str类型则根据系统指定的defaultencoding作为解码格式，解码成unicode**</font>，若是unicode，则先将a进行一次编码，即调用encode()，这个encode默认以环境的defaultencoding作为解码格式（这里我们设定为了utf8）,<font color="purple">**编码成了utf8之后**</font>，再根据环境的defaultencoding作为解码格式，解码成unicode，那么这整个过程是
**a.encode("utf8").decode("utf8")**

其目标是生成一个unicode类型的元素

看完以上，我们最需要注意的也就出来了：
**在使用encode和decode的时候，不仅仅要看括号里面传的是什么参数，更需要看defaultencoding是什么格式，因为其默认会使用defaultencoding进行一次中间转换**，很多时候，我们的报错就是在这种时刻，如下代码
```python
#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
import chardet

a = "你好"

print type(a)
print chardet.detect(a)
print chardet.detect(a.encode("utf8"))

#>>> <type 'str'>
#>>> {'confidence': 0.7525, 'language': '', 'encoding': 'utf-8'}
#>>> Traceback (most recent call last):
#>>>   File "/home/work/weixin_image/encode_test.py", line 15, in <module>
#>>>     print chardet.detect(a.encode("utf8"))
#>>> UnicodeDecodeError: 'ascii' codec can't decode byte 0xe4 in position 0: ordinal not in range(128)
```
我们来看上面的报错，首先，解释器看到中文的字符串，会将其以utf8编码保存，这一点我们在前两行的输出也能看出来
但是最后一行我们执行了encode("utf8")，报的错误是
-<font color="red">**'ascii' codec can't decode byte 0xe4 in position 0: ordinal not in range(128)**</font>-

根据我们之前说的encode和decode的实际过程我们来设想下就是："你好".decode("ascii").encode("utf8") ，好了，我们看到问题了，原来是在decode("ascii")的时候报出的错---<font color="purple">**中文无法用ascii编码表示，正常来说是什么编码就应该用对应的编码去decode，这里是utf8，自然需要decode("utf8")**</font>

但也有例外，注意：<font color="red">**ascii编码的元素可以decode('ascii') 或 decode('utf8') 得到unicode字符**</font>

你可以想象得到，万一你要在你的py脚本中从某个地方获取（从网页上读取，读文件，读数据库...等等），你得到某一个元素，并且你要使用它，但它可能是中文，可能是英文，那么如果你没指定sys.setdefaultencoding('utf8')那就糟糕了，所有的中文都将解析不出来，并且程序遇到中文就报错

要避免这种大规模伤害，你最好还是设定sys.setdefaultencoding('utf8')，我们尽可能在程序中将所有字符规范成utf8

**当然纯英文的注意一点,英文的话你就算指定encode成utf8，它也会默认转化成ascii**，这个设定应该是为了节约空间，否则你想想，一个ascii用三位来表示，浪费多大内存
### End
下一篇继续介绍unicode和ascii以及utf8等等一些编码格式的由来，以及unicode具体如何编码成utf8










