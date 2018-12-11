---
layout: post
date: 2018-12-07 00:00:00
title: "PowerShell 技能连载 - 查找打开的防火墙端口"
description: PowerTip of the Day - Finding Open Firewall Ports
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
以下是一段连接到本地防火墙并转储所有打开的防火墙端口的 PowerShell 代码：

```powershell
$firewall = New-object -ComObject HNetCfg.FwPolicy2
$firewall.Rules |  Where-Object {$_.Action -eq 0} | 
    Select-Object Name, ApplicationName,LocalPorts
```

结果看起来类似这样：

    Name           ApplicationName                                         LocalPorts
    ----           ---------------                                         ----------
    pluginhost.exe C:\users\tobwe\appdata\local\skypeplugin\pluginhost.exe *         
    pluginhost.exe C:\users\tobwe\appdata\local\skypeplugin\pluginhost.exe *         
    spotify.exe    C:\users\tobwe\appdata\roaming\spotify\spotify.exe      *         
    spotify.exe    C:\users\tobwe\appdata\roaming\spotify\spotify.exe      *     


在 Windows 10 和 Server 2016 中，有一系列现成的跟防火墙有关的 cmdlet：

```powershell
PS> Get-Command -Noun *Firewall*

CommandType     Name                                               Version    Source                    
-----------     ----                                               -------    ------                    
Function        Copy-NetFirewallRule                               2.0.0.0    NetSecurity               
Function        Disable-NetFirewallRule                            2.0.0.0    NetSecurity               
Function        Enable-NetFirewallRule                             2.0.0.0    NetSecurity               
Function        Get-NetFirewallAddressFilter                       2.0.0.0    NetSecurity               
Function        Get-NetFirewallApplicationFilter                   2.0.0.0    NetSecurity               
Function        Get-NetFirewallInterfaceFilter                     2.0.0.0    NetSecurity               
Function        Get-NetFirewallInterfaceTypeFilter                 2.0.0.0    NetSecurity               
Function        Get-NetFirewallPortFilter                          2.0.0.0    NetSecurity               
Function        Get-NetFirewallProfile                             2.0.0.0    NetSecurity               
Function        Get-NetFirewallRule                                2.0.0.0    NetSecurity               
Function        Get-NetFirewallSecurityFilter                      2.0.0.0    NetSecurity               
Function        Get-NetFirewallServiceFilter                       2.0.0.0    NetSecurity               
Function        Get-NetFirewallSetting                             2.0.0.0    NetSecurity               
Function        New-NetFirewallRule                                2.0.0.0    NetSecurity               
Function        Remove-NetFirewallRule                             2.0.0.0    NetSecurity               
Function        Rename-NetFirewallRule                             2.0.0.0    NetSecurity               
Function        Set-NetFirewallAddressFilter                       2.0.0.0    NetSecurity               
Function        Set-NetFirewallApplicationFilter                   2.0.0.0    NetSecurity               
Function        Set-NetFirewallInterfaceFilter                     2.0.0.0    NetSecurity               
Function        Set-NetFirewallInterfaceTypeFilter                 2.0.0.0    NetSecurity               
Function        Set-NetFirewallPortFilter                          2.0.0.0    NetSecurity               
Function        Set-NetFirewallProfile                             2.0.0.0    NetSecurity               
Function        Set-NetFirewallRule                                2.0.0.0    NetSecurity               
Function        Set-NetFirewallSecurityFilter                      2.0.0.0    NetSecurity               
Function        Set-NetFirewallServiceFilter                       2.0.0.0    NetSecurity               
Function        Set-NetFirewallSetting                             2.0.0.0    NetSecurity               
Function        Show-NetFirewallRule                               2.0.0.0    NetSecurity
```

<!--more-->
本文国际来源：[Finding Open Firewall Ports](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-open-firewall-ports)
