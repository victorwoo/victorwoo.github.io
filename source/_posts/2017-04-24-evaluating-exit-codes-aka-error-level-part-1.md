---
layout: post
date: 2017-04-24 00:00:00
title: "PowerShell 技能连载 - 评估 Exit Code（也叫做 Error Level – 第一部分）"
description: "PowerTip of the Day - Evaluating Exit Codes (aka Error Level – Part 1)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当运行一个控制台应用程序时，它通常会返回一个数字型的 exit code。该 exit code 的含义取决于控制台应用程序，要查询应用程序才能理解 exit code 的含义。PowerShell 也会将 exit code 传递给用户。它通过 `$LASTEXITCODE` 体现。

以下是一个使用 ping.exe 来测试网络响应的例子：

```powershell
$hostname = 'powershellmagazine.com'
# run console-based executable directly
# and disregard text results
$null = ping.exe $hostname -n 2 -w 2000
# instead look at the exit code delivered in
# $LASTEXITCODE. Ping.exe returns 0 if a 
# response was received:
$IsOnline = $LASTEXITCODE -eq 0
$IsOnline
```

<!--本文国际来源：[Evaluating Exit Codes (aka Error Level – Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/evaluating-exit-codes-aka-error-level-part-1)-->
