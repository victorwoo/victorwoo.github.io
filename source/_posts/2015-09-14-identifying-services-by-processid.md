---
layout: post
date: 2015-09-14 11:00:00
title: "PowerShell 技能连载 - 用 ProcessID 定位服务"
description: PowerTip of the Day - Identifying Services by ProcessID
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Group-Object` 是一个创建查询表的很好的命令。如果您希望用进程 ID 来定位一个 Windows 服务，以下是实现方法：

    $serviceList = Get-WmiObject -Class Win32_Service | Group-Object -Property ProcessID -AsString -AsHashTable

一旦变量被赋值之后，只需要用进程 ID 作为属性即可：

    PS> $serviceList.672
    
    
    ExitCode  : 0
    Name      : WSearch
    ProcessId : 672
    StartMode : Auto
    State     : Running
    Status    : OK

<!--本文国际来源：[Identifying Services by ProcessID](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-services-by-processid)-->
