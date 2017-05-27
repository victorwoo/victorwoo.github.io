layout: post
date: 2017-05-23 00:00:00
title: "PowerShell 技能连载 - 冒充 ToString() 方法"
description: PowerTip of the Day - ToString() Masquerade
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
在前一个技能当中我们解释了 `ToString()` 描述一个对象的方法是含糊的，而且对象的作者可以决定 `ToString()` 返回什么。这在 PowerShell 代码中尤为明显。请看要覆盖任意一个对象的 `ToString()` 方法是多么容易：

```powershell
PS> $a = 1
PS> $a | Add-Member -MemberType ScriptMethod -Name toString -Value { 'go away' } -Force
PS> $a
go away
PS> $a.GetType().FullName
System.Int32
PS> $a -eq 1
True
```

<!--more-->
本文国际来源：[ToString() Masquerade](http://community.idera.com/powershell/powertips/b/tips/posts/tostring-masquerade)
