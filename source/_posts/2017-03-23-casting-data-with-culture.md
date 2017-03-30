layout: post
date: 2017-03-23 00:00:00
title: "PowerShell 技能连载 - 按区域转换数据"
description: PowerTip of the Day - Casting Data with Culture
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
当转换数据（将它转换为不同的数据类型）时，PowerShell 支持两种不同的方式方式。

以下是一个例子：

```powershell
[DateTime]'12.1.2017'
'12.1.2017' -as [DateTime]
```

两行代码都将一个字符串转为一个 DateTime 对象。第一行代码代表强制转换。它可能成功也有可能失败，并且它总是使用语言中性的格式（US 格式），所以它应为一个 月-日-年 格式。

第二行代表“尝试转换”：该转换要么成功要么静默地返回 `$null`。该转换遵循当前的区域设置，所以如果您在一个德文系统众运行这段代码，这段文字被解释成 日-月-年 格式。

<!--more-->
本文国际来源：[Casting Data with Culture](http://community.idera.com/powershell/powertips/b/tips/posts/casting-data-with-culture)
