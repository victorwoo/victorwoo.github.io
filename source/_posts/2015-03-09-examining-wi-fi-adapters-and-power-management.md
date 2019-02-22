---
layout: post
date: 2015-03-09 11:00:00
title: "PowerShell 技能连载 - 检测 Wi-Fi 适配器和电源"
description: PowerTip of the Day - Examining Wi-Fi Adapters and Power Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 Windows 8.1/Server 2012 R2_

Windows 8.1 和 Server 2012 R2 带来了一系列好用的网卡管理 cmdlet。例如当您希望调查 Wi-Fi 连接问题时，或是检查为什么 Wake-On-LAN 功能未能唤醒机器时，检查网卡电源管理设置就十分有意思了。

现在是小菜一碟了：
     
    PS> Get-NetAdapter
    
    Name                      InterfaceDescription                   ifIndex Status
                           
    ----                      --------------------                    ------- -----
    Bluetooth-Netzwerkverb... Bluetooth-Gerät (PAN)                         7 Di...
    WiFi                      Intel(R) Wireless-N 7260                      3 Up   
    
    
    
    PS> Get-NetAdapter -Name WiFi
    
    Name                      InterfaceDescription                   ifIndex Status
                          
    ----                      --------------------                    ------- -----
    WiFi                      Intel(R) Wireless-N 7260                      3 Up    
     

只要您知道网卡的名称，那么查询它电源管理设置的方法是：

     
    PS> Get-NetAdapter -Name WiFi | Get-NetAdapterPowerManagement
    
    
    InterfaceDescription    : Intel(R) Wireless-N 7260
    Name                    : WiFi
    ArpOffload              : Enabled
    NSOffload               : Enabled
    RsnRekeyOffload         : Enabled
    D0PacketCoalescing      : Enabled
    SelectiveSuspend        : Unsupported
    DeviceSleepOnDisconnect : Disabled
    WakeOnMagicPacket       : Enabled
    WakeOnPattern           : Enabled 
     

请注意您需要管理员权限来查看电源管理设置，否则会得到一个误导性的错误信息，提示设备工作不正常。

<!--本文国际来源：[Examining Wi-Fi Adapters and Power Management](http://community.idera.com/powershell/powertips/b/tips/posts/examining-wi-fi-adapters-and-power-management)-->
