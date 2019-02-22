---
layout: post
date: 2017-04-26 00:00:00
title: "PowerShell 技能连载 - 评估 Exit Code（也叫做 Error Level – 第三部分）"
description: "PowerTip of the Day - Evaluating Exit Codes (aka Error Level – Part 3)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中运行控制台应用程序的迷你系列的第三部分中，有一个小课题：如何独立于 PowerShell 运行一个控制台应用程序，并且当它执行完成后得到通知，并且获取它的 exit code？

以下是实现方法：以下代码在一个独立（隐藏）的窗口中运行 ping.exe。PowerShell 继续运行并且可以执行任何其它操作。在这个例子中，它在 ping.exe 正忙于 ping 一个主机名的同时打出一系列“点”号。

当 exe 执行完成时，这段代码能获取进程的 ExitCode 信息：

```powershell
$hostname = 'powershellmagazine.com'
# run the console-based application ASYNCHRONOUSLY in its own
# window (PowerShell continues) and return the
# process object (-PassThru)
# Hide the new window (you can also show it if you want)
$process = Start-Process -FilePath ping -ArgumentList "$hostname -n 4 -w 2000" -WindowStyle Hidden -PassThru

# wait for the process to complete, and meanwhile
# display some dots to indicate progress:
do
{
    Write-Host '.' -NoNewline
    Start-Sleep -Milliseconds 300
} until ($process.HasExited)
Write-Host

# the Error Level information is then found in ExitCode:
$IsOnline = $process.ExitCode -eq 0
$IsOnline
```

<!--本文国际来源：[Evaluating Exit Codes (aka Error Level – Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/evaluating-exit-codes-aka-error-level-part-3)-->
