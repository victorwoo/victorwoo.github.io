---
layout: post
date: 2020-02-10 00:00:00
title: "PowerShell 技能连载 - 区分 IPv4 和 IPv6"
description: PowerTip of the Day - Separating IPv4 and IPv6
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您要获取所有网卡的IP地址，但按地址类型将它们分开。这是一种仅使用 `Select-Object` 的实现方法：

```powershell
function Get-IPAddress
{
  Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
  Where-Object { $_.IPEnabled -eq $true } |
  # add two new properties for IPv4 and IPv6 at the end
  Select-Object -Property Description, MacAddress, IPAddress, IPAddressV4, IPAddressV6 |
  ForEach-Object {
    # add IP addresses that match the filter to the new properties
    $_.IPAddressV4 = $_.IPAddress | Where-Object { $_ -like '*.*.*.*' }
    $_.IPAddressV6 = $_.IPAddress | Where-Object { $_ -notlike '*.*.*.*' }
    # return the object
    $_
  } |
  # remove the property that holds all IP addresses
  Select-Object -Property Description, MacAddress, IPAddressV4, IPAddressV6
}

Get-IPAddress
```

结果看起来类似这样：

    Description                          MacAddress        IPAddressV4   IPAddressV6
    -----------                          ----------        -----------   -----------
    Realtek USB GbE Family Controller #3 00:E0:4C:F4:A9:35 10.4.121.75   fe80::8109:a41e:192b:367

<!--本文国际来源：[Separating IPv4 and IPv6](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/separating-ipv4-and-ipv6)-->

