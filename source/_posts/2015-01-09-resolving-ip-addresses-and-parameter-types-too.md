layout: post
date: 2015-01-09 12:00:00
title: "PowerShell 技能连载 - 解析 IP 地址（和参数类型）"
description: PowerTip of the Day - Resolving IP Addresses (and Parameter Types, Too)
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
_适用于 PowerShell 2.0 及以上版本_

这个例子演示了两件事情：如何限制一个参数为指定的数据类型、如何使用 .NET 方法来将 IP 地址转化为机器名：

    function Resolve-IPAddress 
    {    
        param (
            [IPAddress] 
            $IPAddress
        )
    
        [Net.DNS]::GetHostByAddress($IPAddress)
    } 

通过为 `$IPAddress` 参数前附加一个类型（例如“`IPAddress`”），您可以让 PowerShell 来校验输入数据的合法性。

“`System.Net.DNS`” .NET 类型提供了许多有用的静态方法供您解析 IP 地址。请注意在 PowerShell 中您不需要为 .NET 类型指定“System”命名空间。如果您愿意，您也可以使用完整的“`System.Net.DNS”全名。

这是您使用了新的 `Resolve-IPAddress` 函数的效果：

    PS> Resolve-IPAddress -IPAddress 127.0.0.1
    
    HostName                     Aliases                     AddressList                
    --------                     -------                     -----------                
    TobiasAir1                   {}                          {127.0.0.1}                
    
    
    
    PS> Resolve-IPAddress -IPAddress 300.200.100.1
     Resolve-IPAddress : Cannot process argument transformation on parameter 
    'IPAddress'. Cannot convert value "300.200.100.1" to type "System.Net.IPAddress". 
    Error: "An invalid IP address was specified."
    At line:1 char:30
    + Resolve-IPAddress -IPAddress 300.200.100.1
    +                              ~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [Resolve-IPAddress], ParameterBindin 
       gArgumentTransformationException
        + FullyQualifiedErrorId : ParameterArgumentTransformationError,Resolve-IPAddres 
       s

<!--more-->
本文国际来源：[Resolving IP Addresses (and Parameter Types, Too)](http://powershell.com/cs/blogs/tips/archive/2015/01/09/resolving-ip-addresses-and-parameter-types-too.aspx)
