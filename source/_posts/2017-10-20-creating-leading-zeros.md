---
layout: post
date: 2017-10-20 00:00:00
title: "PowerShell 技能连载 - 补零"
description: PowerTip of the Day - Creating Leading Zeros
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
您是否曾需要将数字转换为以零开头的字符串，例如生成服务器名？只需要使用 PowerShell 的 `-f` 操作符：

```powershell
$id = 12
'server{0:d4}' -f $id
```

以下是输出结果：

```
server0012
```

`-f` 操作符左边是文本模板，右边是数值。在文本模板中，用 `{x}` 作为右侧数值的占位符。占位符的下标从 0 开始。

要在左侧补零，使用 `d`（digit 的缩写）加上您需要的数字位数即可。

<!--more-->
本文国际来源：[Creating Leading Zeros](http://community.idera.com/powershell/powertips/b/tips/posts/creating-leading-zeros)
