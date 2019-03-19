---
layout: post
date: 2015-08-12 11:00:00
title: "PowerShell 技能连载 - 快速获取 IP 地址"
description: PowerTip of the Day - Quickly Getting IP Addresses
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您是否希望快速获取您的机器或是网络上的机器的 IP 地址列表？以下是实现方法：

    #requires -Version 3

    $ComputerName = ''

    [System.Net.Dns]::GetHostAddresses($ComputerName).IPAddressToString

要只取 IPv4 地址，请使用这种方法：

    #requires -Version 1

    $ComputerName = ''

    [System.Net.Dns]::GetHostAddresses($ComputerName) |
    Where-Object {
      $_.AddressFamily -eq 'InterNetwork'
    } |
    Select-Object -ExpandProperty IPAddressToString

类似地，要获取 IPv6 地址，请改成这种方法：

    #requires -Version 1

    $ComputerName = ''

    [System.Net.Dns]::GetHostAddresses($ComputerName) |
    Where-Object {
      $_.AddressFamily -eq 'InterNetworkV6'
    } |
    Select-Object -ExpandProperty IPAddressToString

<!--本文国际来源：[Quickly Getting IP Addresses](http://community.idera.com/powershell/powertips/b/tips/posts/quickly-getting-ip-addresses)-->
