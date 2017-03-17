layout: post
date: 2017-03-13 16:00:00
title: "PowerShell 技能连载 - 快速创建对象数组"
description: PowerTip of the Day - Creating Object Arrays on the Fly
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
以下是一个用内置的 CSV 处理器生成对象数组的代码实例：

```powershell
$csv = @'
PC,Date
PC82012,2017-02-28
PC82038,2017-02-28
PC83073,2017-02-28
PC84004,2017-02-28
PC84009,2017-02-28
PC84015,2017-02-28
PC90435,2017-02-28
'@

$data = $csv | ConvertFrom-Csv

$data
$data | Out-GridView
```

如果一个脚本需要一个静态的服务器、连接数据或其他信息的列表，这种方式会很有用。

<!--more-->
本文国际来源：[Creating Object Arrays on the Fly](http://community.idera.com/powershell/powertips/b/tips/posts/creating-object-arrays-on-the-fly)
