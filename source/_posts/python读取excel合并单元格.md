---
title: python读取excel合并单元格
date: 2018-03-04 23:54:53
tags: [openpyxl,excel]
categories: [python]
---
## 本文介绍如何使用python读取excel中的合并单元格
<!-- more -->
### 问题来源
这几天接到一个产品同事发来的excel文件，需要提取出这份excel的一些组合关键词，之前大部分的需求都是直接对接其他的RD同事，一般都是读库写库之类的，excel的操作确实用的比较少。在读excel的过程中，就遇到了以下的问题
![图一](/python读取excel合并单元格/1.png)
正常的读取都是按照行和列的位置来的，我需要读取的数据是：每一行的演唱者和歌曲名称，即：<font color="purple">**清醒+好极了 / 清醒+记录散落了，没有声音**</font> 等,但若是这样读取读出来很多为None的数据，解决它
### 使用openpyxl自带的函数
```python
import openpyxl

cf = openpyxl.load_workbook(filename="path/to/file")#,read_only=True)
sheets = cf.get_sheet_names()
for sheet in sheets:
    current_wb = cf.get_sheet_by_name(sheet)
    for block in current_wb.merged_cell_ranges:
        #operator.....
```
其中merged_cell_ranges是个属性，其为一个list，如下所示
```text
['A1:D1', 'E1:N1', 'B3:B12', 'C3:C12', 'C13:C21']
```
其中每个元素的意思是：从A1到D1是合并单元格，从E1到N1是合并单元格，依次类推。横坐标是A，B.....，纵坐标为1,2.....
<font color="purple">**对我而言，我要取得是一行一行的数据，只需要选择其中的横坐标相等的那些元素，并且在读取excel遇到这些元素的那个区间范围，取得纵坐标靠较小的值**</font>
比如：'B3:B12'，在这个3~12范围内的值都是取B3这个单元格的值（纵坐标为3），依照图上图一取得值为：清醒，一次类推
**注：如果加上read_only=True会报错如下**
```text
AttributeError: 'ReadOnlyWorksheet' object has no attribute 'merged_cell_ranges'
```
### 使用自己想的方法

#### 方法一，用纵坐标值定位
```python
import openpyxl

excel = openpyxl.load_workbook("path/to/file")
wb = excel.get_sheet_by_name("sheet_name")

loc = 0
#这里我的excel的前两行都是无关的数据，所以纵坐标直接从3开始
for item in range(3,wb.max_row+1):
    try:
        #这种方式读取贼他么慢，换换其他的方法
        artist_name = wb.cell(row=item, column=2).value
        if artist_name:
            loc = 0
        if not artist_name:
            loc += 1
        artist_name = wb.cell(row=item - loc, column=2).value
        song_name  = wb.cell(row=item, column=4).value
        #由于歌名是必须要一行一个的，当没有歌名直接跳过
        if not song_name:
            continue
    except Exception,e:
        print e
        continue
```

##### 不足之处
在使用wb.cell(row=item, column=2)查找元素时，可能是由于每次调用这个函数excel都在定位，所以导致操作起来特别慢，如果是操作比较大（如有几万行++）的excel文件，修改这个excel会变得格外地慢，不建议用这种方法

#### 方法二，用合并单元格本身的第一行值定位
什么意思呢？即:B3~B12，由于B4～B12都是None值，<font color="red">**我们在读取到下一个非None值之前，都使其等于之前记录的那个值**</font>（即合并单元格的第一行的值）
```python
import openpyxl

excel = openpyxl.load_workbook("path/to/file")
wb = excel.get_sheet_by_name("sheet_name")

real_data = list(wb.rows)[2:]
for data in real_data:
    try:
        artist_name = data[1].value
        if artist_name:
            first_row = artist_name
        if not artist_name:
            artist_name = first_row
        artist_name = artist_name
        song_name = data[3].value
        if not song_name:
            continue
    except Exception, e:
        print e
        continue
```
这种方式快的多，因为是直接将所有数据读到内存里，然后一行一行操作这整个excel的值，建议使用方法二

--------
### end
大家可以根据自己的需要去调整修改代码，以上代码只是按照我想要的数据格式去读取的excel