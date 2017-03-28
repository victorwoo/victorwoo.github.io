layout: post
date: 2016-12-09 00:00:00
title: "PowerShell 技能连载 - 查找不合规的命令动词"
description: PowerTip of the Day - Finding Unapproved Verbs
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
Cmdlet 和函数只能用认可的动词以便于用户查找命令，并且保持一致性。

以下是一个快速的审计代码，能够显示不符合这个规定的所有命令：

```powershell
$approved = Get-Verb | Select-Object -ExpandProperty Verb

Get-Command -CommandType Cmdlet, Function |
  Where-Object { $approved -notcontains $_.Verb }
```

这里返回的是所有不符合规定或根本没有命令动词的 cmdlet 和函数。

<!--more-->
本文国际来源：[Finding Unapproved Verbs](http://community.idera.com/powershell/powertips/b/tips/posts/finding-unapproved-verbs)
