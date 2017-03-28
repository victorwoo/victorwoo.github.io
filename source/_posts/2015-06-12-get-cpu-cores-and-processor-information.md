layout: post
date: 2015-06-12 11:00:00
title: "PowerShell 技能连载 - 获取 CPU 核心和处理器信息"
description: PowerTip of the Day - Get CPU Cores and Processor Information
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
通过一行 WMI 代码，就可以查看您的 CPU 详情：

    PS> Get-WmiObject -Class Win32_Processor | Select-Object -Property Name, Number*
    
    Name                                    NumberOfCores NumberOfLogicalProcessors
    ----                                    ------------- -------------------------
    Intel(R) Core(TM) i7-26...                          2                         4

<!--more-->
本文国际来源：[Get CPU Cores and Processor Information](http://community.idera.com/powershell/powertips/b/tips/posts/get-cpu-cores-and-processor-information)
