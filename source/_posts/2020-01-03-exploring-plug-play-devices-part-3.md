---
layout: post
date: 2020-01-03 00:00:00
title: "PowerShell 技能连载 - 探索即插即用设备（第 3 部分）"
description: PowerTip of the Day - Exploring Plug&amp;Play Devices (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何使用 `UPnP.UPnPDeviceFinder` 来查找网络中的设备。您已了解到如何枚举所有的根设备 ("`upnp:rootdevice`")，以及如何通过设备的唯一标识符来访问设备。

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("upnp:rootdevice", 0) | Out-GridView
```

在这一部分中，让我们完成搜索类型，看看如何枚举所有设备（而不仅仅是根设备），以及如何枚举设备类型组。

要列出所有设备，请使用 "`ssdb:all" 而不是 "`upnp:rootdevice`":

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("ssdp:all", 0) | Out-GridView
```

结果包括根设备（“`IsRootDevice`” 为 `$true`，“`ParentDevice`”为空）以及所有子设备（“`IsRootDevice`” 为 `$false`，“`ParentDevice`” 指向该设备链接到的上级设备）。

在 “`UniqueDeviceName`” 中，可以找到可用于直接访问设备的唯一设备名称：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByUDN("uuid:...", 0)
```

每个设备都属于一个类别，该类别在“`Type`”中显示。要查看类型列表，请尝试以下操作：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("ssdp:all", 0) |
    Select-Object -ExpandProperty Type |
    Sort-Object -Unique
```

结果取决于网络中找到的设备。这是我得到的清单：

    urn:dial-multiscreen-org:device:dial:1
    urn:schemas-upnp-org:device:Basic:1
    urn:schemas-upnp-org:device:InternetGatewayDevice:1
    urn:schemas-upnp-org:device:MediaRenderer:1
    urn:schemas-upnp-org:device:WANConnectionDevice:1
    urn:schemas-upnp-org:device:WANDevice:1

要查找特定类型的所有设备，请将该类型与 `FindByType()` 一起使用：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("urn:schemas-upnp-org:device:InternetGatewayDevice:1", 0)
```

最后一点：设备是否响应组搜索，甚至是“upnp:rootdevice”，都取决于设备及其实现。在我的场景中，即使存在那种类型的设备，我也无法获得“Basic”和“WANDevice”组的结果。

如果找不到特定设备，请尝试适用于所有设备的唯一搜索，然后通过“ssdp:all”列出所有设备。如果设备现在显示出来，则可以通过 `Where-Object` 使用“ssdp：all”和客户端过滤，或者通过查找唯一的设备标识符并通过其 UDN 和 `FindByUDN()` 直接访问特定设备来加快搜索速度。

<!--本文国际来源：[Exploring Plug&amp;Play Devices (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-plug-play-devices-part-3)-->

