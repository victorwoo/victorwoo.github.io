---
layout: post
date: 2017-01-02 00:00:00
title: "PowerShell 技能连载 - 解析纯文本（第二部分）"
description: PowerTip of the Day - Parsing Raw Text (Part 2)
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
在前一个技能中我们解释了如何使用 `Select-String` 和正则表达式从纯文本结果中提取有用的信息：

```powershell
PS C:\> $data = ipconfig | select-string 'IPv4' 
PS C:\> [regex]::Matches($data,"\b(?:\d{1,3}\.){3}\d{1,3}\b") | Select-Object -ExpandProperty Value

192.168.2.112
```

PowerShell 支持 `-match` 参数，它也能够处理正则表达式。不过它在一行里只能找到一个匹配项。在多数场景中这也不是大问题，因为一行中通常只包含了一个匹配项。您所做的只需要在管道中使用 `-match`，则原始的数据会逐行地输入：

```powershell
PS C:\> ipconfig | 
  # do raw filtering to only get lines with this word
  Where-Object { $_ -like '*IPv4*' } |
  # do RegEx filtering to identify the value matching the pattern
  Where-Object { $_ -match '\b(?:\d{1,3}\.){3}\d{1,3}\b' } | 
  # return the results from -match which show in $matches
  Foreach-Object { $matches[0] }

192.168.2.112
```

<!--more-->
本文国际来源：[Parsing Raw Text (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/parsing-raw-text-part-2)
