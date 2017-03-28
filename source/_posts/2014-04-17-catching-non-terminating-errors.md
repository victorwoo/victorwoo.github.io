layout: post
title: "PowerShell 技能连载 - 捕获非终止性错误"
date: 2014-04-17 00:00:00
description: PowerTip of the Day - Catching Non-Terminating Errors
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
非终止性错误是在 cmdlet 内部处理的错误。多数在 cmdlet 中产生的错误都是非终止性错误。

您无法用异常处理器来捕获这些错误。所以虽然在这个例子中有一个异常处理器，它也无法捕获 cmdlet 错误：

    try
    {
      Get-WmiObject -Class Win32_BIOS -ComputerName offlineIamafraid 
    }
    catch
    {
      Write-Warning "Oops, error: $_"
    } 
    

要捕获非终止性错误，您必须将它们转换为终止性错误。可以通过设置 `-ErrorAction` 参数为 `"Stop"` 来实现：

    try
    {
      Get-WmiObject -Class Win32_BIOS -ComputerName offlineIamafraid -ErrorAction Stop
    }
    catch
    {
      Write-Warning "Oops, error: $_"
    } 
    
如果您不想一个一个为异常处理器中所有的 cmdlet 添加 `-ErrorAction Stop` 参数，您可以临时将 `$ErrorActionPreference` 变量设置为 `"Stop"`。该设置用于一个 cmdlet 没有显示地设置 `-ErrorAction` 的情况。

<!--more-->
本文国际来源：[Catching Non-Terminating Errors](http://community.idera.com/powershell/powertips/b/tips/posts/catching-non-terminating-errors)
