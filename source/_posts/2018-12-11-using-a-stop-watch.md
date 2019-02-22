---
layout: post
date: 2018-12-11 00:00:00
title: "PowerShell 技能连载 - 使用一个停表"
description: PowerTip of the Day - Using a Stop Watch
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中，要测量时间，您可以简单将一个 datetime 值减去另一个 datetime 值：

```powershell
$Start = Get-Date

$null = Read-Host -Prompt "Press ENTER as fast as you can!"

$Stop = Get-Date
$TimeSpan = $Stop - $Start
$TimeSpan.TotalMilliseconds
```

一个优雅的实现是用停表：

```powershell
$StopWatch = [Diagnostics.Stopwatch]::StartNew()

$null = Read-Host -Prompt "Press ENTER as fast as you can!"

$StopWatch.Stop()
$StopWatch.ElapsedMilliseconds
```

使用停表的好处是可以暂停和继续。

<!--本文国际来源：[Using a Stop Watch](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-a-stop-watch)-->
