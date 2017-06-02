---
layout: post
title: "PowerShell 技能连载 - 获取无线网卡"
date: 2014-03-18 00:00:00
description: PowerTip of the Day - Get-WirelessAdapter
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
在上一个技巧中，我们演示了如何使用注册表信息来查找无线网卡。以下是一个可以返回您系统中所有无线网卡的 `Get-WirelessAdapter` 函数：

    function Get-WirelessAdapter
    {
      Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\*\*\Connection' -ErrorAction SilentlyContinue |
        Select-Object -Property MediaSubType, PNPInstanceID |
        Where-Object { $_.MediaSubType -eq 2 -and $_.PnpInstanceID } |
        Select-Object -ExpandProperty PnpInstanceID |
        ForEach-Object {
          $wmipnpID = $_.Replace('\', '\\')
          Get-WmiObject -Class Win32_NetworkAdapter -Filter "PNPDeviceID='$wmipnpID'"
        } 
    } 
    
    

只需要运行该函数：

![](/img/2014-03-18-get-wirelessadapter-001.png)

由于该函数返回一个 WMI 对象，所以您可以获知该网卡当前是否是活动的，或者启用禁用它。

以下代码将取出网卡对象，然后禁用它，再启用它：

    $adapter = Get-WirelessAdapter
    $adapter.Disable().ReturnValue
    $adapter.Enable().ReturnValue 

请注意返回值 5 意味着您没有足够的权限。请以管理员身份运行该脚本。

<!--more-->
本文国际来源：[Get-WirelessAdapter](http://community.idera.com/powershell/powertips/b/tips/posts/get-wirelessadapter)
