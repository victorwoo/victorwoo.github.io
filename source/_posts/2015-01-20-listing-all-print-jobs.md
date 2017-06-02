---
layout: post
date: 2015-01-20 12:00:00
title: "PowerShell 技能连载 - 列出所有打印任务"
description: PowerTip of the Day - Listing All Print Jobs
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
_适用于 Windows 8.1 或 Server 2012 R2_

Windows 8.1 和 Server 2012 R2 引入了一个名为“PrintManagement”的模块。它包含了管理本地和远程打印机所需的所有 cmdlet。

要列出指定计算机的所有打印任务，首先确定可用的打印机，然后用循环取出每个打印机的打印任务。这实际做起来十分简单：

    $ComputerName = $env:COMPUTERNAME
    
    Get-Printer -ComputerName $ComputerName |  ForEach-Object { 
      Get-PrintJob -PrinterName $_.Name -ComputerName $ComputerName
     } 

如果该代码返回空，那么说明没有打印任务（或者您没有读取它们的权限）。

<!--more-->
本文国际来源：[Listing All Print Jobs](http://community.idera.com/powershell/powertips/b/tips/posts/listing-all-print-jobs)
