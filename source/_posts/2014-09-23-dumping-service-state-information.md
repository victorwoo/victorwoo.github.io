layout: post
date: 2014-09-23 11:00:00
title: "PowerShell 技能连载 - 导出服务状态信息"
description: 'PowerTip of the Day - Dumping Service State Information '
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

如果您想将一个 PowerShell 命令的结果保存到磁盘上，以便传到另一台机器上，以下是简单的实现方法：

    $Path = "$env:temp\mylist.xml"
    
    Get-Service | 
      Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME -PassThru | 
      Export-Clixml -Depth 1 -Path $Path
    
    explorer.exe "/select,$Path" 

这段代码用 `Get-Service` 获取所有的服务。结果添加了一个“ComputerName”字段，用于保存生成的数据所在的计算机名。

然后，得到的结果被序列化成 XML 并保存到磁盘上。接着在目标文件夹打开资源管理器，并且选中创建的 XML 文件。这样您就可以方便地将它拷到 U 盘中随身带走。

要将结果反序列化成真实的对象，使用以下代码：

    $Path = "$env:temp\mylist.xml"
    
    Import-Clixml -Path $Path

<!--more-->
本文国际来源：[Dumping Service State Information ](http://community.idera.com/powershell/powertips/b/tips/posts/dumping-service-state-information)
