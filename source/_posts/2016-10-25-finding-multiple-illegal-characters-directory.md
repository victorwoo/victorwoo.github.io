layout: post
date: 2016-10-25 00:00:00
title: "PowerShell 技能连载 - 查找多个非法字符"
description: PowerTip of the Day - Finding Multiple Illegal Characters
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
之前发，我们演示了如何用 `-match` 操作符来查找一段文本中的非法字符。不过，`-match` 操作符只能查找第一个匹配项。要列出字符串中的所有非法字符，请使用这种方法：

```powershell
# some email address
$mail = 'THOMAS.börßen_senbÖrg@test.com'
# list of legal characters, inverted by "^"
$pattern = '[^a-z0-9\.@]'

# find all matches, case-insensitive
$allMatch = [regex]::Matches($mail, $pattern, 'IgnoreCase')
# create list of invalid characters
$invalid = $allMatch.Value | Sort-Object -Unique 

'Illegal characters found: {0}' -f ($invalid -join ', ')
```

结果看起来如下：

    Illegal characters found: _, ö, ß


<!--more-->
本文国际来源：[Finding Multiple Illegal Characters](http://community.idera.com/powershell/powertips/b/tips/posts/finding-multiple-illegal-characters-directory)
