---
layout: post
date: 2023-04-11 00:00:09
title: "PowerShell 技能连载 - 使用 PowerShell 解决问题（第 4 部分）"
description: PowerTip of the Day - Solving Problems with PowerShell (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 为您提供了丰富的方法来解决任务。它们总是归结为相同的策略。在这个小系列中，我们将逐一说明它们。

以下是要解决的问题：获取计算机的 MAC 地址。

在我们之前的提示中，我们看过命令和运算符。但如果你仍然无法获得所需信息怎么办？

即使如此，PowerShell 也有选项可供选择，因为您可以直接访问 .NET Framework 类型和方法。或者换句话说：如果没有程序员替您完成工作并提供特定命令，则可以自己编写功能。

显然，这可能很快成为最困难的方法，因为现在您需要具备程序员技能，并且需要更多地搜索谷歌。你需要找到一个内置的 .NET 类型来处理你所需的信息。

经过一番研究后，您可能会发现 `[System.Net.NetworkInformation.NetworkInterface]` .NET类型管理网络适配器，并且在 PowerShell 中，所有 .NET 类型后添加两个冒号，即可访问其方法：

```powershell
PS C:\> [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()


Id                   : {DC7C0CE2-B070-4070-B5CB-1C400DA69AF8}
Name                 : vEthernet (Default Switch)
Description          : Hyper-V Virtual Ethernet Adapter
NetworkInterfaceType : Ethernet
OperationalStatus    : Up
Speed                : 10000000000
IsReceiveOnly        : False
SupportsMulticast    : True

Id                   : {44FE83FC-7565-4B18-AAC8-AB3EC075E822}
Name                 : Ethernet 2
Description          : USB Ethernet
NetworkInterfaceType : Ethernet
OperationalStatus    : Up
Speed                : 1000000000
IsReceiveOnly        : False
SupportsMulticast    : True

...
```

由于 .NET 返回结构化数据，因此 PowerShell cmdlet 返回的结果与原始 .NET 方法返回的结果之间没有区别。您可以以相同的方式消耗和处理数据：

```powershell
PS C:\> [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Select-Object -Property Name, NetworkInterfaceType, Description

Name                         NetworkInterfaceType Description
----                         -------------------- -----------
vEthernet (Default Switch)               Ethernet Hyper-V Virtual Ethernet Adapter
Ethernet 2                               Ethernet USB Ethernet
Local Area Connection* 1            Wireless80211 Microsoft Wi-Fi Direct Virtual Adapter
Local Area Connection* 2            Wireless80211 Microsoft Wi-Fi Direct Virtual Adapter #2
WLAN                                Wireless80211 Killer(R) Wi-Fi 6 AX1650s 160MHz Wireless Network Adapter (201D2W)
Bluetooth Network Connection             Ethernet Bluetooth Device (Personal Area Network)
Loopback Pseudo-Interface 1              Loopback Software Loopback Interface 1
```
但是，您找到的.NET方法可能不直接包含所需信息。在我们的示例中，`GetAllNetworkInterfaces()` 返回所有网络适配器，但要获取它们的 MAC 地址，则需要深入了解 .NET 对象树。这就使得使用这种技术变得更加困难（但也令人兴奋和有益）。

这是获取有关您的网络适配器的所有所需信息的完整 .NET 代码，甚至包括特定适配器当前是否处于活动状态的信息：

```powershell
[System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
  ForEach-Object {
      $nic = $_

      [PSCustomObject]@{
          Name = $_.Name
          Status = $_.OperationalStatus
          Mac   = [System.BitConverter]::ToString($nic.GetPhysicalAddress().GetAddressBytes())
          Type = $_.NetworkInterfaceType
          SpeedGb = $(if ($_.Speed -ge 0) { $_.Speed/1000000000 } )
          Description  = $_.Description
      }
  }
```

这就是整个工作闭环之处：通过将此原始 .NET 代码封装到 PowerShell 函数中，您可以向 PowerShell 词汇表添加一个新的简单命令：

```powershell
function Get-MacAddress
{
    [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
      ForEach-Object {
          $nic = $_

          [PSCustomObject]@{
              Name = $_.Name
              Status = $_.OperationalStatus
              Mac   = [System.BitConverter]::ToString($nic.GetPhysicalAddress().GetAddressBytes())
              Type = $_.NetworkInterfaceType
              SpeedGb = $(if ($_.Speed -ge 0) { $_.Speed/1000000000 } )
              Description  = $_.Description
          }
      }
}
```

一旦你运行了这个函数定义代码，就可以再次使用一个高度专业且易于使用的 PowerShell 命令，并附加你常用的一组 PowerShell cmdlet（`Select-Object`、`Where-Object`），将数据处理成所需的形式：

```powershell
PS C:\> Get-MacAddress | Where-Object Mac | Select-Object -Property Name, Status, Mac, SpeedGb

Name                         Status Mac               SpeedGb
----                         ------ ---               -------
vEthernet (Default Switch)       Up 00-15-5D-58-46-A8      10
Ethernet 2                       Up 80-3F-5D-05-58-91       1
Local Area Connection* 1       Down 24-EE-9A-54-1B-E6
Local Area Connection* 2       Down 26-EE-9A-54-1B-E5
WLAN                           Down 24-EE-9A-54-1B-E5    0,78
Bluetooth Network Connection   Down 24-EE-9A-54-1B-E9   0,003
```

<!--本文国际来源：[Solving Problems with PowerShell (Part 4)](https://blog.idera.com/database-tools/powershell/powertips/solving-problems-with-powershell-part-4/)-->

