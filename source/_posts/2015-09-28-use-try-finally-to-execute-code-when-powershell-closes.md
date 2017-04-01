layout: post
date: 2015-09-28 11:00:00
title: "PowerShell 技能连载 - 用 try..finally 在 PowerShell 关闭时执行代码"
description: "PowerTip of the Day - Use try…finally to Execute Code when PowerShell Closes"
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
如果您需要在 PowerShell 退出之前执行一些代码，您可以像这样简单地使用 `try`..`finally` 代码块：

    try {
        # some code
        Start-Sleep -Seconds 20
    } finally {
        # this gets executed even if the code in the try block throws an exception
        [Console]::Beep(4000,1000)
    }

这段代码模拟一段长时间运行的脚本。甚至您关闭 PowerShell 窗口时，在 finally 块中的代码也会在 PowerShell 停止之前执行。

当然这得当脚本确实在运行时才有效。

<!--more-->
本文国际来源：[Use try…finally to Execute Code when PowerShell Closes](http://community.idera.com/powershell/powertips/b/tips/posts/use-try-finally-to-execute-code-when-powershell-closes)
