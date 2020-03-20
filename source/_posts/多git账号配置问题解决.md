---
title: 多git账号配置问题解决
date: 2018-08-10 19:08:56
tags: [git, 代码控制]
categories: git
---
## 本文介绍在单台电脑上使用多个git账号
<!-- more --> 
### 背景

　　需求原因：由于在公司有一个gitlab账号，本身自己又有一个github账号，两个账号的邮箱不同
　　目标：每次提交代码，不需要手动输入账号密码，一键push，自动识别是哪个账号对应的项目

　　这本是半年前就已经解决了的问题，但由于最近换了台本子，所以重新部署了下开发环境和代码相关，期间又遇到了一些小问题，故在此做一次总结，方便以后类似的操作

### 正常操作过程

#### 生成ssh-key公钥/秘钥
```
cd ~/.ssh/

ssh-keygen -t rsa -C "your mail"

#这时候提示你输入秘钥的名字：id_rsa_tingyun
#设定秘钥的密码：xxxxxx

#接着add到环境中
ssh-add ~/.ssh/id_rsa

#如果add失败，执行如下命令：
ssh-agent bash

#之后再执行add操作
ssh-add ~/.ssh/id_rsa |
```
　　按照你的需求，可以重复以上过程，生成不同的 ssh-key 公钥-私钥对，比如：id_rsa_tingyun / id_rsa_work / …..
　　之后，记录下公钥和私钥的内容即可，公钥是需要add到github/gitlab的网页的个人设定中去的，相当于一个账号本（有请求过来，先查下这个账号本里面的账号，再检查请求中的密码是不是正确的），私钥则在本地保存，相当于一个密码。

#### 配置多个账号自动识别
```python
vi ~/.ssh/config

#添加如下内容
Host github.com
 HostName github.com
 User git
 IdentityFile ~/.ssh/id_rsa_tingyun

Host gitlab.xxxx.com
 HostName gitlab.xxxxx.com
 User git
 IdentityFile ~/.ssh/id_rsa_work |
```
　　Host的名字随便取，方便你记忆
　　HostName：取服务器的地址
　　User：一般在github下的，取名为git，我试过了gitlab取名为git也没什么影响
　　<font color="red">**完成以上配置的话，一般我们的repo就能一键push了，但是，根据实际情况不同，还可能会遇到如下的问题，我们来一一解决**</font>

### 存在问题解决

#### 关于ssh keys

　　ssh-keys 分成公钥和私钥，公钥是放在你的github / gitlab 的网页的settings中的，供我们这些客户端连接的时候认证

**公钥**
　　<font color="red">当我们已经有生成好了的ssh-keys，且已经在正常使用的话—即你已经在github/gitlab的主页配置好了公钥，那么只需要关心私钥的配置了。如果没有，那么按照后续的教程配置</font>
**私钥**
　　ssh-keys的公钥则一般是在github/gitlab上配置好了，每次配置新机器我们只需要记得：<font color="red">**找到公钥对应的私钥就行了**</font>， 然后把私钥拷贝到当前的机器上，按照以下操作执行即可开心push

#### 在新机器上配置

　　id_rsa_xxx 这个就是私钥文件，在你原先的电脑上拷贝其内容过来即可
```python
touch ~/.ssh/id_rsa_tingyun
#将拷贝过来的内容粘贴到id_rsa_tingyun中

chmod 600 ~/.ssh/id_rsa_tingyun

#添加认证
ssh-add ~/.ssh/id_rsa_tingyun |
```
　　github的话也是类似，ssh-key保留着就一直用就行了

#### 关于github设定好了ssh-key依旧提示输入账号密码

　　原因：你拷贝项目的时候git clone 的是 https的项目，你应该拷贝git@github..开头的那种url，否则依旧需要密码
　　注意：https的项目就是需要输入账号密码，和其认证方式有关系，https的认证没有使用ssh-key去自动认证

#### github提交历史记录没有变绿问题

　　以上的步骤完成了，那么我们正常提交代码就是一键自动push了，但你会发现你的github上的历史记录的小格子没有变绿，这是什么问题呢？
　　原因：<font color="red">**当你在没有设定好user.name 和user.email的时候，你提交的任何历史记录都不会让你的记录栏颜色变绿**</font>
　　使用多个账号的时候，最好不要使用全局git账号，应该在每个项目下面设定好自己的名字和邮箱，否则在提交的代码是不会让提交的历史记录那一栏变绿的
```python
#在当前的repo根目录下输入下面两行
git config user.name "tingyunsay"

git config user.email "xxxxx@163.com" |
```
　　这样，我们就能一键push，并且github上的历史提交栏正常变绿（无论你本地的repo是https的还是ssh的）

### End

　　若在文章中发现任何问题还请指出，谢谢！

