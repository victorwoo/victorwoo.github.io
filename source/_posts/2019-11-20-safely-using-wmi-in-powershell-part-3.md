---
layout: post
date: 2019-11-20 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中安全地使用 WMI（第 3 部分）"
description: PowerTip of the Day - Safely Using WMI in PowerShell (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在这个迷你系列中，我们在探索 `Get-WmiObject` 和 `Get-CimInstance` 之间的差异。未来的 PowerShell 版本不再支持 `Get-WMIObject`，因此，如果您尚未加入，则需要切换到 `Get-CimInstance`。


在前一个部分中您学习了对于 WMI 类，两个 cmdlet 返回相同的基本信息，但是两个 cmdlet 添加的元数据属性差异显著，并且偶然情况下，属性的数据类型也不相同。例如，日期和时间类型在 `Get-CimInstance` 命令中返回的是 `DateTime` 类型，而在 `Get-WmiObject` 命令中返回的是字符串类型。不过总的来说，差异不大，容易调整。

当您在网络上查询，`Get-WmiObject` 和 `Get-CimInstance` 的差异就比较明显了：

* `Get-WmiObject` 使用 DCOM 进行所有远程处理。它是硬连线的。DCOM 是一个旧的远程处理协议。它使用大量的资源，需要在防火墙中打开许多端口。
* `Get-CimInstance` 缺省情况下使用的是 WinRM 并且工作方式类似 Web Service。不过，您可以通过多种方式改变这种行为，所以远程处理层可以和实际的 WMI 查询层分离。

当连到旧的服务器时，您可能会注意到这个区别，服务器能正确响应 `Get-WmiObject` 但是对于 `Get-CimInstance` 命令抛出异常。旧的服务器只支持旧的 DCOM 协议。

以下是您如何告诉 `Get-CimInstance` 回落到 `Get-WmiObject` 使用的旧式 DCOM 协议：

```powershell
# replace server name to some server that you control
$server = 'SOMESERVER1'

# Get-CimInstance uses WinRM remoting by default
Get-CimInstance -ClassName Win32_BIOS -ComputerName $server

# telling Get-CimInstance to use the old DCOM to contact an old system
$options = New-CimSessionOption -Protocol Dcom
$session = New-CimSession -SessionOption $options -ComputerName $server
Get-CimInstance -ClassName Win32_BIOS -CimSession $session
Remove-CimSession -CimSession $session
```

如您所见，您可以配置一个 `CimSession` 对象，它是可以充分配置的。使用 CIMSession 对象而不是计算机名还有一个额外的好处：您可以在多个查询中复用该会话来节约许多时间。只需要确保结束时关闭会话即可。

<!--本文国际来源：[Safely Using WMI in PowerShell (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/safely-using-wmi-in-powershell-part-3)-->

