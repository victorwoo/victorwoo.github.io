---
layout: post
date: 2017-03-20 00:00:00
title: "PowerShell 技能连载 - 限制文本的长度（第二部分）"
description: PowerTip of the Day - Texts with Maximum Length (Part 2)
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
以下是确保一段文本不超过指定长度的另一种策略。和前一个技能不同的是，当文本长度小于最大长度时，这段代码不会补齐空格：

```powershell
$text = 'this'
$MaxLength = 10
$CutOff = [Math]::Min($MaxLength, $text.Length)
$text.Substring(0,$CutOff)
```

关键点在 `Min()` 函数，它决定了两个值中小的哪个。

<!--more-->
本文国际来源：[Texts with Maximum Length (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/texts-with-maximum-length-part-2)
