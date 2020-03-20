---
title: ajax事件绑定--多id同一事件
date: 2017-08-21 22:48:23
tags: [flask , ajax , 前端]
categories: [flask]
---
## 本文介绍如何为多个id/class绑定同一事件

<!-- more -->

### 背景
最近在修改一个项目的前端部分，需要添加一些所需要的功能，但苦于自身只是在上学时期学过一点点关于前端的知识，简单的一些ajax交互，元素选择。就js这门高深的语言来说，也没有系统地学习过，所以在看别人的js代码时候总是会折腾很长时间，并且想要针对做改动也是比较头疼，但既然要做，就必须硬着头皮去看，把自己遇到过的东西连带总结下

在使用flask渲染前台页面时，我将一个list参数传递给了前端显示，在前端写了一个for循环，展示到一个table中的多行（tr/td）,这样一来使得生成的table中的多个相同元素的id和class，如下
```html
{% for i in all_info %}
...... <!-- 省略多个td，这里我们只关心我们要绑定的事件，且只用删除作为示例 -->
<td>
    <form method="POST" action="{{ url_for('delete')}}">
        <input type="hidden" value={{ i.name }} class="delete_name" name="delete_name">
        <button id="sub" type="submit" value="delete" class="btn btn-default btn-lg">Delete</button>
    </form>
</td>
{% endfor %}
```

这里我们只拿delete事件来举个例子，如上的代码会生成很多具有相同id="sub"的button元素，所以我开始是使用一个form表单去做的提交，虽然能实现删除操作，但是对于这种比较危险的操作，最好多加几层判断为好，这时候需要用js来控制是一个比较好的解决方法
但就如我们之前所说的，这时候是多个相同id/class的选择，我们不能像往常一样使用$('.xxx') / $('#xxx') 来选中元素的值并进行ajax传值，所以后面将使用$(this).parent()来进行选择

### 解决方法

#### 将form表单去掉，用一个div块包起来
```html
{% for i in all_info %}
<td>
    <div id="fuck">
        <input type="hidden" value={{ i.name }} class="delete_name" name="delete_name">
        <button id="sub" type="button" value="delete" class="btn btn-default btn-lg">Delete</button>
    </div>
</td>
{% endfor %}
```
#### 使用$(this).parent('div').children('.xxxx')进行取值

注：<font color="red">**这里是使用parent，而不是parents（parents会取得this的全部父元素，那个东西就太多了，每往上一层就是一个）**</font>

```javascript
<script>
$("[id=sub]").click(function fk(){  
    var statu = confirm("确定删除用户?");
    if(!statu){
       return false;
    }
    var s = $(this).parent('div').children(".delete_name").val();
    $.ajax({
            type: "POST",
            url: "/delete",
            data: {
                'delete_name': s,
            },
            dataType: 'json',
            success: function (data) {
                if (data.status == 200) {
                    //location.href = data.location;
                    alert("delete success!");
                    location.href = data.location;
                                        }
                                     },
            error: function (data) {
                    alert("delete failed!");
                    location.href = data.location;
                    }
    });
});
</script>
```
在选中的元素（id为sub的所有元素），我们选中只会有一个，由于要传递的值都是相同的class，所以不能像通常的通过唯一标签来取得唯一值，智能用this，找到其唯一的父元素（这也是我为什么用div将其包起来的原因），再寻找父元素下唯一的那个我们<font color="red">准备好的值（这里是".delete_name"）</font>，将其作为ajax需要的值传递过去

#### 后端接收代码如下
```python
@app.route('/delete' , methods=['POST',])
@login_required
def delete():
    right_info = request.form.to_dict()
    spidermanagerdb = app.config['spidermanagerdb']
    cas_user_name = cas.username
    drop_name = right_info.get('delete_name')
    if drop_name:
        spidermanagerdb.drop(drop_name)
        return json.dumps({'status': 200, 'location': "/check_cas/" + cas.username})
    else:
        return json.dumps({'status': 400, 'location': "/check_cas/" + cas.username})
```
在返回中，ajax可以捕获返回的data，从而判断所做的操作结果如何，从而告知操作的用户。我这里无论访问值是什么，均执行了一步:重定向到/check_cas/<username>（这个页面也是我们执行delete的页面），也就相当于刷新了这个页面


### END
之后对待这种相同id/class的表单元素的事件绑定，均可以采用类似的方法实现，<font color="red">包裹住一层div，然后使用parent来进行选值</font>
方法肯定不止这一种，待以后找到更简单的方法，继续分享

参考文章:
http://blog.csdn.net/cui_angel/article/details/7903704
http://blog.csdn.net/jdhanhua/article/details/6125231



