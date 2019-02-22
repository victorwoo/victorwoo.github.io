---
layout: post
date: 2017-03-17 00:00:00
title: "PowerShell 技能连载 - 限制文本的长度（第一部分）"
description: PowerTip of the Day - Texts with Maximum Length (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想将一个文本的长度限制在某一个长度，以下是一个简单的方法：

```powershell
$text = 'this is a long text'
$MaxLength = 10

$text.PadRight($MaxLength).Substring(0,$MaxLength)
```

这段代码首先对文本填充，以防它比最大长度还短，然后使用 `Substring()` 裁剪掉多余的文本。

<!--本文国际来源：[Texts with Maximum Length (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/texts-with-maximum-length-part-1)-->
