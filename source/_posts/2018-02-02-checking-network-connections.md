---
layout: post
date: 2018-02-02 00:00:00
title: "PowerShell 技能连载 - 检查网络连接"
description: PowerTip of the Day - Checking Network Connections
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的机器通过不同网络连接，连到了 internet（或 VPN），以下两个函数可能对您有用。

`Get-ActiveConnection` 列出当前所有获取到 IP 地址的网络连接。`Test-ActiveConnection` 接受一个关键字并检查是否有一个名字中包含该关键字的活动连接。

```powershell
function Get-ActiveConnection
{
    Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPAddress } |
    Select-Object -ExpandProperty Description
}

function Test-ActiveConnection
{
    param([Parameter(Mandatory)]$Keyword)


    @(Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
    Where-Object { $_.IPAddress } |
    Where-Object { $_.Description -like "*$Keyword*" }).Count -gt 0

}
```

以下是一个快速的演示输出：

```powershell
PS> Get-ActiveConnection
Dell Wireless 1820A 802.11ac

PS> Test-ActiveConnection dell
True

PS> if ( (Test-ActiveConnection dell) ) { Write-Warning "Connected via DELL network card" }
WARNING: Connected via DELL network card

PS>
```

<!--本文国际来源：[Checking Network Connections](http://community.idera.com/powershell/powertips/b/tips/posts/checking-network-connections)-->
