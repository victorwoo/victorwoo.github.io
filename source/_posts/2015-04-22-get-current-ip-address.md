layout: post
date: 2015-04-22 11:00:00
title: "PowerShell 技能连载 - 获取当前 IP 地址"
description: PowerTip of the Day - Get Current IP Address
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
以下是一段您计算机绑定的所有 IP 地址的代码：

    #requires -Version 1
    
    
    $ipaddress = [System.Net.DNS]::GetHostByName($null)
    Foreach ($ip in $ipaddress.AddressList)
    {
      $ip.IPAddressToString
    }

如果您将 `$null` 替换为主机名（例如“_server123_”），就可以获取对应计算机绑定的 IP 地址。

如果您只需要获取 IPv4 地址，请试试这段代码：

    #requires -Version 1
    
    
    $ipaddress = [System.Net.DNS]::GetHostByName($null)
    foreach($ip in $ipaddress.AddressList)
    {
      if ($ip.AddressFamily -eq 'InterNetwork')
      {
        $ip.IPAddressToString 
      }
    }

<!--more-->
本文国际来源：[Get Current IP Address](http://community.idera.com/powershell/powertips/b/tips/posts/get-current-ip-address)
