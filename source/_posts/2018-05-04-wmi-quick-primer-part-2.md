---
layout: post
date: 2018-05-04 00:00:00
title: "PowerShell 技能连载 - WMI 快速入门（第 2 部分）"
description: PowerTip of the Day - WMI Quick Primer (Part 2)
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
有两个 cmdlet 可以获取 WMI 数据：旧的 `Get-WmiObject` cmdlet 和新的 `Get-CimInstance` cmdlet。当在本地使用时，两者的行为十分相像。然而当远程使用的时候，两者的区别十分明显。

以下是两个示例调用，分别从远程系统中获取共享的文件（请确保调整了计算机名）：

```powershell
Get-WmiObject -Class Win32_Share -ComputerName sr0710
Get-CimInstance -ClassName Win32_Share -ComputerName sr0710
```

（两个调用都需要目标计算机的本地的管理员权限，所以您可能需要添加 `Credential` 参数并且提交一个合法的账户名，如果您当前的用户不满足这些要求的话）

`Get-WmiObject` 总是使用 DCOM 做为传输协议，而 `Get-CimInstance` 使用 WSMAN（一种 WebService 类的通信协议）。多数主流的 Windows 操作系统支持 WSMan，但如果您需要和旧的服务器通信，它们可能只支持 DCOM，这样 `Get-CimInstance` 可能会失败。

`Get-CimInstance` 可以使用 session 参数，这提供了巨大的灵活性，而且运行您选择传输协议。要使用 DCOM（类似 `Get-WmiObject`），请使用以下代码：

```powershell
$options = New-CimSessionOption -Protocol Dcom
$session = New-CimSession -ComputerName sr0710 -SessionOption $options
$sh = Get-CimInstance -ClassName Win32_Share -CimSession $session
Remove-CimSession -CimSession $session
```

<!--more-->
本文国际来源：[WMI Quick Primer (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/wmi-quick-primer-part-2)
