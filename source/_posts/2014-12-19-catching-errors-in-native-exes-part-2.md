layout: post
date: 2014-12-19 12:00:00
title: "PowerShell 技能连载 - 捕获本地 EXE 的错误（第 2 部分）"
description: PowerTip of the Day - Catching Errors in Native EXEs (Part 2)
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

以下是检测控制台程序发出的错误的另一种方法：

    $ErrorActionPreference = 'Continue'
    $result = net.exe user UserDoesNotExist 2>&1 
    
    # $? is $false when something went wrong
    if ($? -eq $false) {
        # read last error:
        $errMsg = $result.Exception.Message -join ','
        Write-Host "Something went wrong: $errMsg"
    } else {
        Write-Host 'All is fine.'
    } 

请注意 `$ErrorActionPreference` 的用法：当它设置为‘`Stop`’时，错误将被转换为一个 .NET 异常。`$ErrorActionPreference` 的缺省设置是‘`Continue`’。通过这个设置，脚本可以通过 `$err` 获得错误信息。

如果最后一次调用失败了，内置的 `$?` 变量将会返回 `$false`。在这种情况下，代码将会返回一条错误信息（或者做其它事情，例如写日志文件）。

<!--more-->
本文国际来源：[Catching Errors in Native EXEs (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/catching-errors-in-native-exes-part-2)
