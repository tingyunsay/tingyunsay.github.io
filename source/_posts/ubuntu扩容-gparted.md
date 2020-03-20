---
title: ubuntu扩容--gparted
date: 2017-10-05 22:04:38
tags: [ubuntu,系统]
categories: [ubuntu]
---
### 本文介绍使用gparted工具为Ubuntu扩容
<!-- more -->
### 背景
博主安装的是双系统，在一个128GB的固态上，只给了Ubuntu 40GB左右的空间，并且在安装系统分区的时候，并没有给根目录（/）分配较多的空间，只分配了15GB左右，开始的一段时间还能用，可随着系统安装的包越来越多，总是只剩下几百兆，我只得不断去删除一些没用的已经安装的软件，比如docker / vagrant....，一开始并没有在意，但次数多了觉得这是个很烦躁的问题，便在网上搜索Ubuntu扩充分区，所以找到了扩大根目录的方法

### 制作gparted启动盘为Ubuntu扩容
你可以使用apt-get install gparted安装gparted来查看本机的磁盘分配情况，但直接在系统中启动gparted并没有什么用处---<font color="purple">**因为你启动了系统所有的磁盘都是mount状态，并不支持重新切分分配**</font>，只能查看分区情况，而查看磁盘情况使用df -h 或者 fdisk -l命令能达到一样的效果
#### tuxboot
```buildoutcfg
apt-add-repository ppa:thomas.tsai/ubuntu-tuxboot
apt-get install tuxboot
```
tuxboot是一个跨平台的制作启动盘的软件，支持制作的启动盘类型有： Clonezilla live, DRBL live, Gparted live, Tux2live.
这里我们要制作的是Gparted启动盘
#### 制作gparted启动盘
```
~#tuxboot
```
在终端输入如上命令，其会打开一个图形化页面，如下图
![图一](/ubuntu扩容-gparted/1.png)
先插入u盘，好让tuxboot启动时读取到
第一行我们选择<font color="red">gparted-live-stable</font>，默认current
点击Save ISO file，其他的都是默认即可，可以看到Drive识别了我们的u盘 /dev/sdc4，如下图
![图一](/ubuntu扩容-gparted/2.png)
最后点击OK，等待其将iso文件下载好，启动盘制作完，我们便可以重启机器了
#### u盘启动并调整分区
和安装系统类似的操作，如果你设定了u盘优先启动，那么直接重启机器即可（否则需要在安全f8或者fxx下将启动mode切换成u盘启动），安装过系统的朋友应该都知道

启动，按照默认选择点击Enter键一步步下去，最后我们到达图形化的Gparted页面，在这里我们可以操作所有处于unmount状态的磁盘，更具体的过程可以查看[<font color="red">**此网站**</font>](https://askubuntu.com/questions/430956/how-to-resize-the-root-partition-using-gparted)

很简单的手工操作，先resize，将/home/目录调小，这样就可以腾出来一块空闲的区域
之后，将/root/目录resize，调节至最大，把空闲区域全部赋予它
这是我重新分区完的磁盘状态
![图一](/ubuntu扩容-gparted/3.png)
可以看到，/dev/sda5这个原先只挂载根目录的空间还挂载了/var/lib/docker/aufs 
#### 注意
若你在分区的过程中遇到无法将空闲分区合并到其他分区，请查看[<font color="purple">**此视频**</font>](https://www.youtube.com/watch?v=cDgUwWkvuIY)，貌似在磁盘分配上面有一些需要遵循的规则
### End
最好的方法是换个全固态的笔记本，或者买个大点的固态安系统，那样就不用担心根目录不够用了(→_→)
