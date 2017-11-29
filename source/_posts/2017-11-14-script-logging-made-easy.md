---
layout: post
date: 2017-11-14 00:00:00
title: "PowerShell 技能连载 - 轻松记录脚本日志"
description: PowerTip of the Day - Script Logging Made Easy
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
从 PowerShell 5 开始，您可以在任何宿主中使用 `Strart-Transcript` 来记录脚本的所有输出内容。以下是向各种脚本轻松添加日志的方法：

```powershell
# add this: ############################
$logFile = "$PSScriptRoot\mylog.txt"
Start-Transcript -Path $logFile -Append
#########################################

"Hello"

($a = Get-Service)

"I received $($a.Count) services."
Write-Host "Watch out: direct output will not be logged!"


# end logging ###########################
Stop-Transcript
#########################################
```

只需要将注释块中的代码添加到脚本的开始和结束处。日志文件将会在脚本所在的目录创建。由于 `$logFile` 使用 `$PSScriptRoot`（脚本的当前文件夹），请确保已经将脚本保存并以脚本的方式运行。否则，`$PSScriptRoot` 变量可能为空。

只需要确保脚本输出所有您需要的信息，就可以在 logfile 中看到它。例如将赋值语句放在括号中，PowerShell 将不只是赋值，而且将它们输出到 output。

警告：除了用 `Write-Host` 直接写到宿主的信息，所有输入输出信息都将被记录下。这些信息只能在屏幕上看到。

<!--more-->
本文国际来源：[Script Logging Made Easy](http://community.idera.com/powershell/powertips/b/tips/posts/script-logging-made-easy)
