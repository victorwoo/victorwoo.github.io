---
layout: post
date: 2018-10-04 00:00:00
title: "PowerShell 技能连载 - 通过 CSV 创建对象"
description: PowerTip of the Day - Using CSV to Create Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候通过简单的基于文本的 CSV 格式来批量创建对象是一种聪明的方法，尤其是原始数据已是基于文本的而且只需要少量重格式化。

以下是一个简单的例子，以这种方式输入信息并创建一个自定义对象的列表：

```powershell
$text = 'Name,FirstName,Location
Weltner,Tobias,Germany
Nikolic,Aleksandar,Serbia
Snover,Jeffrey,USA
Special,ÄÖÜß,Test'

$objects = $text | ConvertFrom-Csv

$objects | Out-GridView
```

结果看起来类似这样：

```powershell
Name    FirstName Location
----    --------- --------
Weltner Tobias    Germany
Nikolic Aleksandar Serbia
Snover  Jeffrey   USA
Special ÄÖÜß      Test
```

<!--本文国际来源：[Using CSV to Create Objects](http://community.idera.com/powershell/powertips/b/tips/posts/using-csv-to-create-objects)-->
