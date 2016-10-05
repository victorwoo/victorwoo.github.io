layout: post
date: 2014-12-16 12:00:00
title: "PowerShell 技能连载 - 捕获本地 EXE 的错误（第 1 部分）"
description: PowerTip of the Day - Catching Errors in Native EXEs (Part 1)
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
_适用于 PowerShell 所有版本_

当您运行本地控制台命令，例如 `robocopy.exe`、`ipconfig.exe` 或类似的命令时，您可以处理这些命令中抛出的错误：

    try
    {
        $current = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        # this will cause an EXE command to emit an error
        # (replace with any console-based EXE command)
        net.exe user nonexistentUser 2>&1
        $ErrorActionPreference = $current
    }
    catch
    {
       Write-Host ('Error occured: ' + $_.Exception.Message)
    } 

要捕获错误，您需要临时将 `$ErrorActionPreference` 设为“`Stop`”。另外，您需要用“`2>&1`”将错误信息重定向到输出控制台。

这么做完之后，例如 .NET 错误等错误就可以被 PowerShell 处理了。

<!--more-->
本文国际来源：[Catching Errors in Native EXEs (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/catching-errors-in-native-exes-part-1)
