layout: post
date: 2014-10-01 11:00:00
title: "PowerShell 技能连载 - 获取 MAC 地址"
description: PowerTip of the Day - Getting MAC Addresses
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

在 PowerShell 中获取网卡的 MAC 地址十分简单。以下是众多方法中的一个：

    PS> getmac /FO CSV | ConvertFrom-Csv 
    
    Physical Address                        Transport Name                         
    ----------------                        --------------                         
    5C-51-4F-62-F2-7D                       \Device\Tcpip_{FF034A81-CBFE-4B11-9D...
    5C-51-4F-62-F2-81                       Media disconnected      

有挑战性的地方在于实际的列名是本地化的，不同语言文化的值差异很大。由于原始信息是来自于 _getmac.exe_ 生成的 CSV 数据，所以有一个简单的技巧：跳过首行（包含 CSV 头部），然后传入自定义的统一列名，以达到对列重命名的效果。

    getmac.exe /FO CSV |
      Select-Object -Skip 1 | 
      ConvertFrom-Csv -Header MAC, Transport 

这将总是产生“_MAC_”和“_Transport_”的列。

当然，也有面向对象的解决方案，例如通过 WMI 查询或者使用 Windows 8.1 或 Server 2012/2012 R2。不过，我们认为所演示的方法是一个有趣的选择并且展示了如何将原始的 CSV 数据转换为真正有用的和语言文化无关的信息。

<!--more-->
本文国际来源：[Getting MAC Addresses](http://community.idera.com/powershell/powertips/b/tips/posts/getting-mac-addresses)
