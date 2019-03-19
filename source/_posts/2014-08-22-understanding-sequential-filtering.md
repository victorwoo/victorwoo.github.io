---
layout: post
date: 2014-08-22 11:00:00
title: "PowerShell 技能连载 - 理解顺序过滤"
description: PowerTip of the Day - Understanding Sequential Filtering
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

当您在解析基于文本的日志文件时，或是需要过滤其它类型的信息时，往往需要使用 `Where-Object` 命令。以下是一些常见的场景，演示如何合并过滤器：

    # logical AND filter for ALL keywords
    Get-Content -Path C:\windows\WindowsUpdate.log |
      Where-Object { $_ -like '*successfully installed*' } |
      Where-Object { $_ -like '*framework*' } |
      Out-GridView

    # above example can also be written in one line
    # by using the -and operator
    # the resulting code is NOT faster, though, just harder to read
    Get-Content -Path C:\windows\WindowsUpdate.log |
      Where-Object { ($_ -like '*successfully installed*') -and ($_ -like '*framework*') } |
      Out-GridView

    # logical -or (either condition is met) can only be applied in one line
    Get-Content -Path C:\windows\WindowsUpdate.log |
      Where-Object { ($_ -like '*successfully installed*') -or ($_ -like '*framework*') } |
      Out-GridView

<!--本文国际来源：[Understanding Sequential Filtering](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-sequential-filtering)-->
