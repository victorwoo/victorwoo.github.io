layout: post
title: "PowerShell 技能连载 - 用 Splatting 技术封装 WMI 调用"
date: 2014-06-04 00:00:00
description: PowerTip of the Day - Use Splatting to Encapsulate WMI Calls
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
Splatting 是向 cmdlet 传递多个参数的好方法。以下例子演示了如何封装 WMI 调用，并且使它们支持不同的名称：

    function Get-BIOSInfo
    {
        param
        (
            $ComputerName,
            $Credential,
            $SomethingElse
        )
    
        $null = $PSBoundParameters.Remove('SomethingElse')
    
        Get-WmiObject -Class Win32_BIOS @PSBoundParameters
    } 

`Get-BIOSInfo` 通过 WMI 获取 BIOS 信息，并且它支持本地、远程以及通过证书的远程调用。这是因为用户向 `Get-BIOSInfo` 传递的实参实际上传递给了 `Get-WmiObject` 对应的参数。所以当一个用户没有传递 `-Credential` 参数，那么就不会向 `Get-WmiObject` 传递 `-Credential` 参数。

Splatting 技术通常使用一个自定义的哈希表，它的每个键代表一个形参，每个值代表一个实参。在这个例子中，使用了一个预定义的 `$PSBoundParameters` 哈希表。它事先插入了要传递给函数的参数。

请确保不要传给目标 cmdlet 它不知道的参数。举个例子，`Get-BIOSInfo` 函数定义了一个“SomethingElse”参数。而 `Get-WmiObject` 没有这个参数，所以您在 splat 之前，您必须先调用 `Remove()` 方法从哈希表中把这个键移掉。

<!--more-->
本文国际来源：[Use Splatting to Encapsulate WMI Calls](http://community.idera.com/powershell/powertips/b/tips/posts/use-splatting-to-encapsulate-wmi-calls)
