---
title: qq_copyright crawler
date: 2017-04-15 09:53:45
tags: [scrapy,qq音乐]
categories: [scrapy]
---

## 本文介绍qq音乐版权信息抓取流程
<!-- more -->

### 页面分析
由于qq音乐歌曲信息过于多,这里不采取和之前一样抓取页面的过程,假设正常要抓取页面,那将造成数千万次的页面访问(<font color="red">**更麻烦其中大部分页面需要渲染**</font>,效率是大问题,负载也是问题),这不是一个良好的爬虫做的事情,所以这里采用<font color="blue">找接口</font>的方式,而且<font color="blue">qq音乐的绝大部分有效数据都是通过json传递的</font>,所以也不是很麻烦,f12分析一下就好了

这里的版权信息是基于album信息中的歌单抓取,通过抓取一个歌手所有album的歌单信息,其中有我们需要的大部分信息

### 为什么不直接抓全部歌曲信息?
答:歌曲信息我试过了,但信息量较少,只能是说除了歌曲名字和歌手名字,其他都是无效数据,而通过album抓则可能会漏掉部分歌曲(<font color="blue">有的歌手没有album,只有一些单曲;还有的歌手有些歌曲并没有放到album中,抓完所有的album会发现缺少了一些歌</font>),但能保证抓取的信息都是带有版权信息的大部分信息(公司,时间,专辑名等....)

### 抓取流程
#### 1.种子页面,构造同级页,并找所有歌手id
https://c.y.qq.com/v8/fcg-bin/v8.fcg?channel=singer&page=list&key=all_all_all&pagesize=100&format=jsonp&pagenum=1
<font color="red">**todo**</font>:找到最大page,生成同级page,循环遍历,接下来从这些页面中找歌手的<font color="blue">singerid</font>

#### 2.找所有专辑id
https://c.y.qq.com/v8/fcg-bin/fcg_v8_singer_album.fcg?g_tk=5381&format=jsonp&singermid=<font color="blue">{singerid}</font>&order=time&begin=0&num=150
#这里我们设定成150个专辑了,没有歌手有这么多的专辑数,所以都是返回所有
<font color="red">**todo**</font>:找到其中的<font color="blue">albumid</font>,构造成如下页面

#### 3.解析详细信息
https://c.y.qq.com/v8/fcg-bin/fcg_v8_album_info_cp.fcg?albummid=<font color="blue">{albumid}</font>&g_tk=5381&format=jsonp
<font color="red">**todo**</font>:从其中提取所有需要的信息

如果后续能发现还有什么更好的接口,保持更新


## 更新 2017-04-15
以上这种方法在实践过程中出现了问题:qq音乐歌手很多都没有专辑专门的显示页面,也就是说第二步无法根据singerid获得所有albumid,也就没法进行下一步的抓取.
换种策略

<font color="blue">根据singerid获取全部歌曲信息api,这里我设定成2000,没有谁的歌曲数比这个多,返回全部数据</font>
https://c.y.qq.com/v8/fcg-bin/fcg_v8_singer_track_cp.fcg?g_tk=5381&format=jsonp&singermid=<font color="blue">{singermid}</font>&begin=0&num=2000

这个接口返回了所有的歌曲信息,每每首歌的信息里带了一个专辑id,我们提取出这个albumid,然后在这一层做一个过滤 ( <font color="red">**可以使用blloomfilter文件过滤,只会多出来一个bloom文件,其他的不用关心**</font> ) , 使得只有不重复的albumid进入到后续的抓取

这样一来,对于那些主页没有专辑信息的歌手,也能拿到所有albumid.因为我们是直接通过的api请求.


## 更新 2017-04-26

以上的方法还有一处存在问题,就是阈值不能设定2000这么大,加入设定这么大,会返回单页的数据也就是默认的20个元素, 这里我们设定为900首
https://c.y.qq.com/v8/fcg-bin/fcg_v8_singer_track_cp.fcg?g_tk=5381&format=jsonp&singermid=<font color="blue">{singermid}</font>&begin=0&num=900

实现代码基于TingyunSpider模板,很多地方还存在不足,但还会继续改进

[<font color="red">**代码地址**</font>](https://github.com/tingyunsay/TingyunSpider)




