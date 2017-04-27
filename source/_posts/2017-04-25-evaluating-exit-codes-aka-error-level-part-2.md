layout: post
date: 2017-04-25 00:00:00
title: "PowerShell 技能连载 - 评估 Exit Code（也叫做 Error Level – 第二部分）"
description: "PowerTip of the Day - Evaluating Exit Codes (aka Error Level – Part 2)"
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
当您直接启动一个控制台应用程序时，PowerShell 会返回它的 exit code（也叫做 Error Level），并存储在 `$LASTEXITCODE` 变量中。然而，如何获取通过 `Start-Process` 启动的控制台应用程序的 exit code 呢？

以下是方法：

```powershell
$hostname = 'powershellmagazine.com'
# run the console-based application synchronously in the PowerShell window, 
# and return the process object (-PassThru)
$process = Start-Process -FilePath ping -ArgumentList "$hostname -n 2 -w 2000" -Wait -NoNewWindow -PassThru

# the Error Level information is then found in ExitCode:
$IsOnline = $process.ExitCode -eq 0
$IsOnline
```

<!--more-->
本文国际来源：[Evaluating Exit Codes (aka Error Level – Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/evaluating-exit-codes-aka-error-level-part-2)
