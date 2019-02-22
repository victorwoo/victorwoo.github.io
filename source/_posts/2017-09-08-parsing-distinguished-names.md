---
layout: post
date: 2017-09-08 00:00:00
title: "PowerShell 技能连载 - 解析完全限定名"
description: PowerTip of the Day - Parsing Distinguished Names
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
完全限定名是字符串的格式，而字符串包含丰富的处理数据方法。最强大而又十分简单的是 `Split()` 方法。

请看使用 `Split()` 解析完全限定名，获取最后一个元素的名称，是多么简单：

```powershell
$dn = 'CN=pshero010,CN=Users,DC=powershell,DC=local'
$lastElement = $dn.Split(',')[0].Split('=')[-1]
$lastElement
```

`Split()` 总是返回一个字符串数组。通过大括号，您可以操作每一个独立的数组元素。所以这段代码首先用逗号分割，然后取出第一个元素，即“CN=pshero010”。然后，再次使用相同的技术，用“=”分割。在这里，我们关心的是最后一个数组元素。PowerShell 支持负的数组下标，它从数组的尾部开始计算，所以下标为 -1 获取的是最后一个数组元素。任务完成！

<!--本文国际来源：[Parsing Distinguished Names](http://community.idera.com/powershell/powertips/b/tips/posts/parsing-distinguished-names)-->
