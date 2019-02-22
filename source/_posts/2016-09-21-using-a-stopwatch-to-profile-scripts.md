---
layout: post
date: 2016-09-21 00:00:00
title: "PowerShell 技能连载 - 用秒表测定脚本执行时间"
description: PowerTip of the Day - Using a Stopwatch to Profile Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否希望了解某个命令或一段脚本运行了多少时间？以下简易的秒表对象能帮您实现这个功能：

```powershell
# create a new stopwatch
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# run a command
$info = Get-Hotfix

# stop the stopwatch, and report the milliseconds
$stopwatch.Stop()
$stopwatch.Elapsed.Milliseconds

# continue the stopwatch
$stopwatch.Start()
# $stopwatch.Restart()  # <- resets stopwatch

# run another command
$files = Get-ChildItem -Path $env:windir

# again, stop the stopwatch and report accumulated runtime in milliseconds
$stopwatch.Stop()
$stopwatch.Elapsed.Milliseconds
```

这个秒表比自己用 `Get-Date` 写的好用得多，并且能计算时间差。这个秒表可以停止、继续、复位，并且能随时自动汇报经历的时间。例如，您可以在检查代码时停止秒表，然后在准备执行下一条命令的时候重启秒表。

在上面的例子中，若您将第二处 `Start()` 改为 `Restart()` 则秒表将会复位并且报告的时间是第二条命令执行的时间而不是总时间。

<!--本文国际来源：[Using a Stopwatch to Profile Scripts](http://community.idera.com/powershell/powertips/b/tips/posts/using-a-stopwatch-to-profile-scripts)-->
