---
layout: post
date: 2016-11-30 00:00:00
title: "PowerShell 技能连载 - 捕获 Native EXE 的错误"
description: PowerTip of the Day - Catching Errors from Native EXEs
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
是否想知道如何捕获 native 控制台 EXE 程序的错误？PowerShell 的错误处理器只能处理 .NET 代码的错误。

这段代码是捕获控制台应用程序错误的框架：

```powershell
try
{
    # set the preference to STOP
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    # RUN THE CONSOLE EXE THAT MIGHT EMIT AN ERROR,
    # and redirect the error channel #2 to the
    # output channel #1
    net user doesnotexist 2>&1
}

catch [System.Management.Automation.RemoteException]
{
    # catch the error emitted by the EXE,
    # and do what you want
    $errmsg = $_.Exception.Message
    Write-Warning $errmsg
}

finally
{
    # reset the erroractionpreference to what it was before
    $ErrorActionPreference = $old
}
```

一旦控制台程序发出一个错误，它就会输出到控制台的 \#2 通道。由于示例代码中该通道直接重定向到普通的 output，所以 PowerShell 能接收到它。当 `ErrorActionPreference` 设成 "`Stop`" 时，PowerShell 会将任何该通道的输入数据转发到一个 .NET `RemoteException`，这样您就可以捕获它。

```
WARNING: The user name  could not be found.
```
<!--more-->
本文国际来源：[Catching Errors from Native EXEs](http://community.idera.com/powershell/powertips/b/tips/posts/catching-errors-from-native-exes)
