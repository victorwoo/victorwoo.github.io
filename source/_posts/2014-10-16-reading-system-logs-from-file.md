---
layout: post
date: 2014-10-16 11:00:00
title: "PowerShell 技能连载 - 从文件中读取系统日志"
description: PowerTip of the Day - Reading System Logs from File
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

有些时候，您可能会需要读取已经导出到磁盘上的系统日志文件，或者您希望直接从一个“evtx”格式的文件中读取系统日志。

以下是实现的方法：

    $path = "$env:windir\System32\Winevt\Logs\Setup.evtx"
    Get-WinEvent -Path $path

<!--本文国际来源：[Reading System Logs from File](http://community.idera.com/powershell/powertips/b/tips/posts/reading-system-logs-from-file)-->
