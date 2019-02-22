---
layout: post
date: 2018-04-10 00:00:00
title: "PowerShell 技能连载 - 创建十六进制数值"
description: PowerTip of the Day - Creating Hexadecimal Values
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一系列方法可以将十进制数据转为十六进制表示：

```powershell
$value = 255

[Convert]::ToString($value, 16)
'{0:x}' -f $value
'{0:X}' -f $value
'{0:x10}' -f $value
'{0:X10}' -f $value
```

<!--本文国际来源：[Creating Hexadecimal Values](http://community.idera.com/powershell/powertips/b/tips/posts/creating-hexadecimal-values)-->
