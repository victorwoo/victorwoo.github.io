---
layout: post
date: 2017-08-29 00:00:00
title: "PowerShell 技能连载 - Get-Service 的替代"
description: PowerTip of the Day - Alternate Get-Service
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
`Get-Service` cmdlet 有一系列缺点。例如，没有一个过滤运行中或停止的服务的参数，并且结果不包含服务的启动模式。

WMI 可以传出这些信息。以下是一个获取最常用服务信息的简单函数：

```powershell
function Get-ServiceWithWMI
{
    param
    (
        $Name = '*',
        $State = '*',
        $StartMode = '*'
    )

    Get-WmiObject -Class Win32_Service |
        Where-Object Name -like $Name |
        Where-Object State -like $State |
        Where-Object StartMode -like $StartMode |
        Select-Object -Property Name, DisplayName, StartMode, State, ProcessId, Description

}
```

以下是调用该命令的方法，这行代码显示所有禁用的服务，包括它们的友好名称和描述：

```powershell
PS C:\> Get-ServiceWithWMI -StartMode Disabled | Out-GridView
```

<!--more-->
本文国际来源：[Alternate Get-Service](http://community.idera.com/powershell/powertips/b/tips/posts/alternate-get-service)
