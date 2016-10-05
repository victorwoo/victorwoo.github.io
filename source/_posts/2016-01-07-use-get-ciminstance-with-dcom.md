layout: post
date: 2016-01-07 12:00:00
title: "PowerShell 技能连载 - 使用 DCOM 协议运行 Get-CimInstance"
description: PowerTip of the Day - Use Get-CimInstance with DCOM
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
PowerShell 3.0 增加了`Get-WmiObject` 的另一个选择：`Get-CimInstance`，它工作起来十分相似但可以从内部 的 WMI 服务中获取信息：

```shell
PS C:\> Get-WmiObject -Class Win32_BIOS

SMBIOSBIOSVersion : A03
Manufacturer      : Dell Inc.
Name              : A03
SerialNumber      : 5TQLM32
Version           : DELL   - 1072009

PS C:\> Get-CimInstance -Class Win32_BIOS

SMBIOSBIOSVersion : A03
Manufacturer      : Dell Inc.
Name              : A03
SerialNumber      : 5TQLM32
Version           : DELL   - 1072009 
```

虽然 `Get-WmiObject` 仍然存在，但 `Get-CimInstance` 绝对是未来的选择。这个 Cmdlet 支持 WMI 类的智能提示（在 PowerShell ISE 中），并且返回的数据可读性更好：例如日期是以人类可读的日期格式返回，而 `Get-WmiObject` 显示 WMI 内部原始的日期格式。

最重要的区别是它们远程工作的方法。`Get-WmiObject` 使用的是旧的 DCOM 协议，而 `Get-CimInstance` 缺省使用的是新的 `WSMan` 协议，不过它是灵活的，可以根据需要退回 DCOM 协议。

以下示例函数通过 `Get-CimInstance` 远程获取 BIOS 信息。该函数缺省采用 DCOM，通过 `-Protocol` 参数您可以选择希望的通信协议：

```powershell
#requires -Version 3
function Get-BIOS
{
    param
    (
        $ComputerName = $env:COMPUTERNAME,

        [Microsoft.Management.Infrastructure.CimCmdlets.ProtocolType]
        $Protocol = 'DCOM'
    )
    $option = New-CimSessionOption -Protocol $protocol
    $session = New-CimSession -ComputerName $ComputerName -SessionOption $option
    Get-CimInstance -CimSession $session -ClassName Win32_BIOS
}
```

<!--more-->
本文国际来源：[Use Get-CimInstance with DCOM](http://powershell.com/cs/blogs/tips/archive/2016/01/07/use-get-ciminstance-with-dcom.aspx)
