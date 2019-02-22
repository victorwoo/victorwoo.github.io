---
layout: post
date: 2017-05-15 00:00:00
title: "PowerShell 技能连载 - 将二进制字符串转为整形"
description: PowerTip of the Day - Converting Binary String to Integer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是将一段二进制文本字符串转为对应的整形值的方法：

```powershell
$binary = "110110110"
$int = [Convert]::ToInt32($binary,2)
$int
```

用另一种方法可以更简单：

```powershell
PS> [Convert]::ToString(438,2)
110110110
```

<!--本文国际来源：[Converting Binary String to Integer](http://community.idera.com/powershell/powertips/b/tips/posts/converting-binary-string-to-integer)-->
