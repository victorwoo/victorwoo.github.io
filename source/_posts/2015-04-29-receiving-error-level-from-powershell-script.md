layout: post
date: 2015-04-29 11:00:00
title: "PowerShell 技能连载 - 从 PowerShell 脚本中接收错误返回值"
description: PowerTip of the Day - Receiving Error Level from PowerShell Script
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
以下是一个演示 PowerShell 如何返回一个数值型状态码给调用者的简单脚本：

    $exitcode = 123
    
    $p = Start-Process -FilePath powershell -ArgumentList "-command get-process; exit $exitcode" -PassThru
    Wait-Process -Id $p.Id
    
    'External Script ended with exit code ' + $p.ExitCode

如果您在 PowerShell 中直接调用该脚本（不使用 `Start-Process`），那么数值型返回值会被赋给 `$LASTEXITCODE`：

    $exitcode = 199
    
    powershell.exe "get-process; exit $exitcode"
    
    'External Script ended with exit code ' + $LASTEXITCODE 

如果您从一个批处理文件或是 VBScript 中运行一段 PowerShell 脚本，该数值型返回值将会赋给 `%ERRORLEVEL%` 环境变量，好比 PowerShell 是一个控制台应用程序一样——实际上 powershell.exe 确实是。

<!--more-->
本文国际来源：[Receiving Error Level from PowerShell Script](http://community.idera.com/powershell/powertips/b/tips/posts/receiving-error-level-from-powershell-script)
