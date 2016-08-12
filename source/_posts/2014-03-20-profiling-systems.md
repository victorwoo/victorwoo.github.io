layout: post
title: "PowerShell 技能连载 - 获取系统信息"
date: 2014-03-20 00:00:00
description: PowerTip of the Day - Profiling Systems
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
如果您只是需要获取本地系统或远程系统的常见配置信息，那么不必浪费时间去研究自己的解决方案。只需要使用 `systeminfo.exe`，然后将数据导入 PowerShell：

    function Get-SystemInfo
    {
      param($ComputerName = $env:COMPUTERNAME)
    
      $header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfiguration','OS Build Type','RegisteredOwner','RegisteredOrganization','Product ID','Original Install Date','System Boot Time','System Manufacturer','System Model','System Type','Processor(s)','BIOS Version','Windows Directory','System Directory','Boot Device','System Locale','Input Locale','Time Zone','Total Physical Memory','Available Physical Memory','Virtual Memory: Max Size','Virtual Memory: Available','Virtual Memory: In Use','Page File Location(s)','Domain','Logon Server','Hotfix(s)','Network Card(s)'
    
      systeminfo.exe /FO CSV /S $ComputerName |
        Select-Object -Skip 1 | 
        ConvertFrom-CSV -Header $header 
    } 

以下是结果：

![](/img/2014-03-20-profiling-systems-001.png)

如果把结果保存到一个变量，您可以很容易地独立存取里面的每一条信息：


如果您想用别的名字来获取信息，只需根据需要改变属性名列表。例如您不喜欢“System Boot Time”，那么只需要在脚本中将它重命名为“BootTime”。

<!--more-->
本文国际来源：[Profiling Systems](http://powershell.com/cs/blogs/tips/archive/2014/03/20/profiling-systems.aspx)
