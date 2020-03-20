---
title: 纳豆app视频播放链解析
date: 2018-03-18 18:26:08
tags: [爱奇艺vf算法,spider]
categories: [spider]
---
## 本文介绍如何获取纳豆app中视频的播放源链
<!-- more -->

### 前言
相信看到这篇文章的很多同学都是在写爬虫的过程中遇到了问题，既然是爬虫，那么你的操作可能也会使得其他人或者自己的工作量变得大，这么说的原因有二：
```text
1.提供服务的那一方可能会因为一些不友好的爬虫，不断地修改策略
2.服务端一旦修改反扒策略，所有涉及这个抓取源的开发者都需要更新
```
由于博主很长一段时间（一年半多）至今都是从事抓取相关的工作，也是由开始的"不友好的爬虫"慢慢意识到自己的很多的"爬虫工作"都更像是在攻击，而不是正正经经的"爬虫"。所以特别想在本文开始之前说一些关于爬虫应该稍微注意的点，不仅仅是为了个人的工作，更是觉得所有为大家贡献代码和思路的探路者都很不容易，总结一下就是：破解不易，且用且珍惜
以下几点
```text
访问频率/访问量，可以根据你对这个网站的数据量评估和自己的数据量需求，控制在一个合理的值，除非特殊情况，不要想着一天能百万千万

能找到接口的网站尽量使用接口，这样能减少对服务器资源请求的压力

好的代理确实不好找（除非花高价，x万/年），如果有可用的代理，使用像squid/nginx之类的代理服务，并且在使用之前动态校验，留下高可用的

大部分设计接口的站点，其接口中应该含有绝大部分数据，能从一个接口里获取到的信息，尽量不要再增加多余的请求
```
注意到以上几点，最起码对方不会把你当成一个恶意程序，像一个正常访问的请求，不会对服务器造成什么不好的影响，何乐而不为

### 问题
在收集一款app叫做"爱奇艺头条"（现已更名为：纳豆）上的短视频时，找寻其播放源链

### 分析
#### 前期抓包
**请求网站：http://m.toutiao.iqiyi.com/top_126hd0mujy.html**

在app端抓包，两次的不同的请求：
http://cache.m.iqiyi.com/jp/tmts/961149300/961149300/?uid=&cupid=&platForm=h5&qyid=&agenttype=13&type=mp4&rate=1&k_ft1=8&qdv=1&qdx=n&qdy=x&qds=0&__jsT=sgve&t=1521166692860&src=02020031010000000000&vf=0b53f9287e1b0a970ed1343392af05c2&callback=tmtsCallback

http://cache.m.iqiyi.com/jp/tmts/961149300/961149300/?uid=&cupid=&platForm=h5&qyid=&agenttype=13&type=mp4&rate=1&k_ft1=8&qdv=1&qdx=n&qdy=x&qds=0&__jsT=sgve&t=1521105711069&src=02020031010000000000&vf=1461673fa3ce9cc1cdef6308c9691171&callback=tmtsCallback

观察其中的参数，只有t和vf不同，这个t很明显能看出来是一个时间戳（13位的），而这个vf就得继续研究了
#### 找寻加密方法
**猜想是不是由某个js文件加密生成的**
于是我按下f12，刷新了下页面，发现在这个播放链出来之前加载了如下几个js文件
![图一](/纳豆app视频播放链解析/1.png)
注：最下面的那个请求是获取详细播放链的url
在图中的js文件中，很轻易便能看到有一个特别显眼的js文件：<font color="red">app_detail_video.18f1b586.js</font>
**http://static.qiyi.com/assets/js/page/detail/app_detail_video.18f1b586.js**
我们进入到以上的js文件中，检索 vf= 这个关键词，找到相关的代码如下
```python
function(e, t, a) {
    var i = window.cmd5xtmts ? window.cmd5xtmts() : {};
    $.extend(a || {}, i, {
        src: "02020031010000000000"
    });
    var n = "/jp/tmts/" + e + "/" + t + "/?" + $.param(a) + "&callback=tmtsCallback";
    return a.vf = window.cmd5x ? window.cmd5x(n) : "", a
}(e, t, a));
```
这里的 <font color="red">a.vf = window.cmd5x ? window.cmd5x(n) : "", a</font>
意思是：<font color="red">**若window这个对象有cmd5x这个方法（属性），就返回window.cmd5x(n)；否则返回""空字符串, 后面的a是第二个返回值**</font>
到这里就出现两个问题：
1.cmd5x这个函数在哪儿?
2.这个n是怎么得到的？

#### **找寻cmd5x这个加密函数**
在所有加载的js文件中都找了一遍，但是还没有明确地看到cmd5x这个function，但是在网上查到的一份有关爱奇艺的vf算法js文件看到如下一段代码
```python
o.exports = {
    request: function(e, t, i) {
        var o = navigator.userAgent.match(/miuivideo\//i) || n.os.android && parseInt(n.os.version) > 4 && navigator.userAgent.match(/MiuiBrowser/i);
        u.sendVrsRequestPingback(),
        r.jsonp({
            url: c.h5tmtsUrl + e.tvid + "/" + e.vid + "/",
            params: function() {
                var t = {
                    platForm: "h5",
                    uid: d.getUid(),
                    dfp: s.get(),
                    cupid: e.cupid,
                    src: p.getSrc(),
                    codeflag: 1,
                    type: n.os.mac && n.browser.SAFARI || n.browser.iPad || n.browser.iPhone || n.os.android && parseFloat(n.os.version) > 4 || o ? "m3u8": "mp4"
                };
                f.isBoss() && (t.nolimit = 1);
                try {
                    l(t, p.cmd5xtmts())
                } catch(e) {}
                return t
            } (),
            beforeSend: function(e) {
                var t = a.parse(e.url).host;
                try {
                    p.cmd5x && (e.url += "&vf=" + p.cmd5x(e.url.replace(new RegExp("^https?://" + t, "ig"), "")))
                } catch(e) {}
                return e
            },
            success: function(e) {
                u.sendVrsReadyPingback(),
                e && e.hasOwnProperty("code") ? "A00000" === e.code ? t(e) : i(e) : i({
                    code: "P00001"
                })
            },
            failure: function() {
                i({
                    code: "P00001"
                })
            }
        })
    }
}
```
能看出来以上是部分关于发送验证请求的代码，主要看beforeSend这一部分，大概能够知道
```python
url: c.h5tmtsUrl + e.tvid + "/" + e.vid + "/",

var t = a.parse(e.url).host;

e.url += "&vf=" + p.cmd5x(e.url.replace(new RegExp("^https?://" + t, "ig"), ""))
```
以上，我们还找到h5tmtsUrl这个未知的变量，又找到如下的代码
注：e.url.replace(new RegExp("^https?://" + t, "ig"), "")
这是将"https://"+e.url的域名 , "ig"表示不区分大小写，统统替换成成空字符串，结合下面提到的来说，也就是将"https://cache.m.iqiyi.com/jp/tmts/" 这一段字符替换成空字符串
```python
function(e, t, i) {
    var o;
    void 0 !== (o = function(e, t, i) {
        var o = window.location.protocol;
        i.exports = {
            vipauthUrl: "https://api.vip.iqiyi.com/services/cknsp.action",
            h5tmtsUrl: o + "//cache.m.iqiyi.com/jp/tmts/",
            vmsUrl: o + "//cache.video.iqiyi.com/jp/vms",
            vmsIPUrl1: "http://115.182.125.142/jp/vms",
            vmsIPUrl2: "http://124.250.53.164/jp/vms",
            pingbackUrl: "http://msg.71.am/core",
            isfanUrl: o + "//sns-api.iqiyi.com/apis/friend/follow.action"
        }
    }.call(t, i, t, e)) && (e.exports = o)
}

```
可以知道
```python
var o = window.location.protocol;

h5tmtsUrl: o + "//cache.m.iqiyi.com/jp/tmts/"
```
h5tmtsUrl其实就是一个通信协议+指定字符串："https" + "//cache.m.iqiyi.com/jp/tmts/"
所以，到这里我们需要解决的是什么呢？cmd5x这个函数我们依然不知道，且我们只能大概知道作为其参数的e.url是一个被替换掉了"https://cache.m.iqiyi.com/jp/tmts/" 的正常url字符串，其可能的参数有如下
```python
url = c.h5tmtsUrl + e.tvid + "/" + e.vid + "/"

#以下这些拼接成字符串
{
    platForm: "h5",
    uid: d.getUid(),
    dfp: s.get(),
    cupid: e.cupid,
    src: p.getSrc(),
    codeflag: 1,
    type: n.os.mac && n.browser.SAFARI || n.browser.iPad || n.browser.iPhone || n.os.android && parseFloat(n.os.version) > 4 || o ? "m3u8": "mp4"
};
```
由于其js文件实在太混乱，所有参数都不知道怎么来的，没法推算出我们应该给这个cmd5x传一个什么样的值，更重要的是js中的cmd5x在哪儿，我该怎么用py去调用都不知道。最后还是在万能的google上扎到了答案，感谢贡献代码的大佬，一路带我前行
#### 来自大佬的微笑
参考了几篇博客，自己也尝试着构造请求，也成功了，大概有以下这些参数是必要的
```python
head = "/jp/tmts/tvid/vid/?"
param = {
        "uid":"",
        "cupid":"",
        "platForm":"h5",
        "qyid":"",
        "agenttype":"13",
        "type":"mp4",
        "nolimit":"",
        "k_ft1":"8",
        "rate":"2",
        "sgti":"",
        "qdv":"1",
        "qdx":"n",
        "qdy":"x",
        "qds":"0",
        "__jsT":"sgve",
        "t":t,
        "src":"02020031010000000000",
        "callback":"tmtsCallback"
    }
```
将param构造成一个字符串，再在头部拼接上head即是一个正常的cmd5x需要的参数，一个正常的出参数值为：
```text
/jp/tmts/12476488409/12476488409/?src=02020031010000000000&callback=tmtsCallback&uid=&sgti=13_12e9e055c713deba092399c62d8cb2b2_1489561211612&agenttype=13&cupid=&t=1521388096000&qdv=1&platForm=h5&rate=2&__jsT=sgve&k_ft1=8&qds=0&nolimit=&qdy=x&type=mp4&qdx=n&qyid=&&vf=39f7f4c1b39089dbfe887ad15f1ffb7a
```
加上对应的头部文件：
"http://cache.m.iqiyi.com"

最后即是我们请求视频链接的地址
http://cache.m.iqiyi.com/jp/tmts/12476488409/12476488409/?src=02020031010000000000&callback=tmtsCallback&uid=&sgti=13_12e9e055c713deba092399c62d8cb2b2_1489561211612&agenttype=13&cupid=&t=1521388096000&qdv=1&platForm=h5&rate=2&__jsT=sgve&k_ft1=8&qds=0&nolimit=&qdy=x&type=mp4&qdx=n&qyid=&&vf=39f7f4c1b39089dbfe887ad15f1ffb7a

其返回的数据格式化后如下：
```python
{
　　"timestamp":"20180318234822",
　　"ctl":{
　　　　"area":1
　　},
　　"code":"A00000",
　　"data":{
　　　　"vipTypes":[

　　　　],
　　　　"screenSize":"854x480",
　　　　"vidl":[
　　　　　　{
　　　　　　　　"vd":1,
　　　　　　　　"screenSize":"854x480",
　　　　　　　　"vid":"e7eb1b37eeb029f6529bde6dc66a4815"
　　　　　　}
　　　　],
　　　　"aid":"",
　　　　"pano":{
　　　　　　"rType":0,
　　　　　　"type":1
　　　　},
　　　　"adDuration":0,
　　　　"messageId":"",
　　　　"head":0,
　　　　"previewType":"",
　　　　"ugc":1,
　　　　"clientIp":"114.248.64.91",
　　　　"prv":"",
　　　　"vd":1,
　　　　"vid":"12476488409",
　　　　"rTime":"",
　　　　"ds":"A00012",
　　　　"lgh":[

　　　　],
　　　　"duration":272,
　　　　"wmarkPos":0,
　　　　"bossStatus":0,
　　　　"cacheTime":1521388047491,
　　　　"tail":0,
　　　　"isProduced":0,
　　　　"cid":5,
　　　　"tipType":"",
　　　　"m3u":"http://222.134.2.36/videos/v1/20180210/59/d2/82ae8f5cf70d7093c1b4dbcfbe667e6b.mp4?key=09bf99dfe8d1239f4fd1deb1192c91f75&dis_k=244569a7f99feb6f8fde7414223cfb756&dis_t=1521388102&dis_dz=CNC-BeiJing&dis_st=40&src=iqiyi.com&uuid=a6e5338-5aae8a46-e&m=v&qd_k=39f7f4c1b39089dbfe887ad15f1ffb7a&sgti=13_12e9e055c713deba092399c62d8cb2b2_1489561211612&qd_ip=72f8405b&qd_p=72f8405b&dfp=&qd_src=02020031010000000000&ssl=&ip=114.248.64.91&qd_vip=0&dis_src=vrs&qd_uid=0&qdv=1&qd_tm=1521388102146",
　　　　"ad":1,
　　　　"exclusive":0,
　　　　"tvid":12476488409,
　　　　"previewTime":"",
　　　　"m3utx":"http://222.134.2.36/videos/v1/20180210/59/d2/82ae8f5cf70d7093c1b4dbcfbe667e6b.mp4?key=09bf99dfe8d1239f4fd1deb1192c91f75&dis_k=244569a7f99feb6f8fde7414223cfb756&dis_t=1521388102&dis_dz=CNC-BeiJing&dis_st=40&src=iqiyi.com&uuid=a6e5338-5aae8a46-e&m=v&qd_k=39f7f4c1b39089dbfe887ad15f1ffb7a&sgti=13_12e9e055c713deba092399c62d8cb2b2_1489561211612&qd_ip=72f8405b&qd_p=72f8405b&dfp=&qd_src=02020031010000000000&ssl=&ip=114.248.64.91&qd_vip=0&dis_src=vrs&qd_uid=0&qdv=1&qd_tm=1521388102146"
　　}
}
```
其中的m3u就是视频真正的播放地址了

cmd5x也有破解好的对应几个版本，其实也叫做vf的算法，针对不同类型
```python
import hashlib

#app端的vf算法
def cmd5x(str):
    vf = hashlib.new('md5', str + '3sj8xof48xof4tk9f4tk9ypgk9ypg5ul').hexdigest()
    return vf

#pc端的vf算法，针对爱奇艺的网页播放
def getPcVf(str):
    vf = hashlib.new('md5', str + 'u6fnp3eok0dpftcq9qbr4n9svk8tqh7u').hexdigest()
    return vf

#针对vip用户的vf算法
def getPcIbt(str):
    vf = hashlib.new('md5', str + 't6hrq6k0n6n6k6qdh6tje6wpb62v7654').hexdigest()
    return vf
```
这里我们使用第一个即可
#### 代码
代码放在[<font color="purple">**github**</font>](https://github.com/tingyunsay/nadou_vf)了，有需要的可以看看


#### 2018/07/12更新
看了下日志，爱奇艺大概是从6月27号更新了策略。不知道是不是被抓的多了....
以上app端的加盐md5算法失效了，花了点时间找到了cmd5x更新后的方法，说下思路：<font color="red">其关键函数藏在一个js文件中，参数也更新了，并且还需要注意某一个参数的先后顺序.</font>

注：我没有使用新的cmd5x方法去加密原始的参数，所以不知道原始的参数是不是能使用。最好还是都替换成新的吧，因为app_detail_video.xxxx.js文件也换了新的

由于怕被封，暂时先不把方法写到这里，还是那句话，接口且用且珍惜.

----------------
### End
在找参数的过程中用到了一个动态调试js的方法，由于本篇篇幅太长，放在下一篇里面单独讲讲这种方法

参考网址：
http://zhuhaidong.win/TP/index.php/Home/Index/article/id/32.html
https://blog.icehoney.me/posts/2016-12-19-Reverse-JavaScript
https://github.com/zhangn1985/ykdl/issues/19
