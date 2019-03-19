---
layout: post
date: 2014-12-10 12:00:00
title: "PowerShell 技能连载 - 解析 DISM 日志文件"
description: PowerTip of the Day - Parsing DISM Log File
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 2.0 及更高版本_

在您的 Windows 文件夹中，您会见到各种系统日志文件。其中一种是 DISM 日志文件，它包含了 Windows 的配置信息（特性状态等）。

以下是一个简单的实践，演示如何解析这类日志文件并得到可用 PowerShell cmdlet 操作的富对象：

    $path = "$env:windir\logs\dism\dism.log"

    Get-Content -Path $path |
    ForEach-Object {
      $_ -replace '\s{2,}', ','
    } |
    ConvertFrom-Csv -Header (1..20) |
    ForEach-Object {
      $array = @()
      $array += $_.1 -split ' '
      $array += $_.2
      $array += $_.3
      $array += $_.4
      $array += $_.5
      $array -join ','
    } |
    ConvertFrom-Csv -Header (1..20) |
    Out-GridView

<!--本文国际来源：[Parsing DISM Log File](http://community.idera.com/powershell/powertips/b/tips/posts/parsing-dism-log-file)-->
