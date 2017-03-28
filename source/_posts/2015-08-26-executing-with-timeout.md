layout: post
date: 2015-08-26 11:00:00
title: "PowerShell 技能连载 - 指定执行超时"
description: PowerTip of the Day - Executing with Timeout
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
`Start-Process` 可以启动进程但是不支持超时。如果您需要在指定的超时时间后结束一个跑飞了的进程，您可以使用类似这样的方法：

    #requires -Version 2
    
    $maximumRuntimeSeconds = 3
    
    $process = Start-Process -FilePath powershell.exe -ArgumentList '-Command Start-Sleep -Seconds 4' -PassThru
    
    try
    {
        $process | Wait-Process -Timeout $maximumRuntimeSeconds -ErrorAction Stop
        Write-Warning -Message 'Process successfully completed within timeout.'
    }
    catch
    {
        Write-Warning -Message 'Process exceeded timeout, will be killed now.'
        $process | Stop-Process -Force
    }

`Wait-Process` 用于等待进程执行。如果它没有在指定的超时之内结束，`Wait-Process` 将抛出一个异常。在相应的错误处理器中可以决定要如何处理。

在这个例子中，`catch` 代码块将结束进程。

这个例子的处理代码是启动第二个 PowerShell 实例，在新的实例中执行 `Start-Sleep` 命令来模拟某些长时间运行的任务。如果您将 `Start-Sleep` 的参数调整为短于 `$maximumRuntimeSeconds` 指定的值，那么操作将会在指定的超时值之内完成，而您的脚本将不会结束该进程。

<!--more-->
本文国际来源：[Executing with Timeout](http://community.idera.com/powershell/powertips/b/tips/posts/executing-with-timeout)
