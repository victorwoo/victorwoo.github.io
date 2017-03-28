layout: post
date: 2016-12-15 00:00:00
title: "PowerShell 技能连载 - 等待进程退出"
description: PowerTip of the Day - Waiting for Processes to Exit
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
有时候，一个 PowerShell 脚本需要等待外部进程结束。以下是一些用户的做法：

```powershell
$processNameToWaitForExit = 'notepad'
do
{
    Start-Sleep -Seconds 1
} while (Get-Process -Name $processNameToWaitForExit -ErrorAction SilentlyContinue)
```

这种做法不太理想，因为它至少等待了一秒钟，即便进程已经不在运行了。以下是一个更好的方法：

```powershell
$processNameToWaitForExit = 'notepad'
Wait-Process -Name $processNameToWaitForExit -ErrorAction SilentlyContinue
```

不仅代码更短，`Wait-Process` 也支持超时时间。如果等待的时间过长，您可以通过超时时间来结束等待。

<!--more-->
本文国际来源：[Waiting for Processes to Exit](http://community.idera.com/powershell/powertips/b/tips/posts/waiting-for-processes-to-exit)
