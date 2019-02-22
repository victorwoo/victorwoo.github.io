---
layout: post
date: 2018-02-12 00:00:00
title: "PowerShell 技能连载 - 读取 RunOnce 注册表键"
description: PowerTip of the Day - Reading RunOnce Key
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 注册表中的 `RunOnce` 键存储了所有的自启动。它可能是空的。要检查自启动的应用程序请试试这段代码：

```powershell
$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
$properties = Get-ItemProperty -Path $path 
$properties
```

再次申明，这个键可能没有内容。如果它有内容，那么每个自启动程序都有它自己的值和名字。如果只要读取自启动程序的路径，请用 `GetValueNames()` 读取这个注册表键。它能够读取注册表值的名称。然后通过 `GetValue()` 读取实际的值：

```powershell
$path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
$key = Get-Item -Path $path
$key.GetValueNames() | ForEach-Object { $key.GetValue($_) }
```

<!--本文国际来源：[Reading RunOnce Key](http://community.idera.com/powershell/powertips/b/tips/posts/reading-runonce-key)-->
