---
layout: post
date: 2020-01-01 00:00:00
title: "PowerShell 技能连载 - 探索即插即用设备（第 2 部分）"
description: PowerTip of the Day - Exploring Plug&amp;Play Devices (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们使用 `UPnP.UPnPDeviceFinder` 来发现连入您网络的智能设备。今天，让我们仔细看看返回的对象。

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$result = $UPnPFinder.FindByType("upnp:rootdevice", 0)
```

当您运行一个搜索（可能需要执行一定的时间），将会获取到许多信息，但是某些属性只是以 `System.__ComObject` 的形式返回。如何查看它们背后隐藏的信息？

让我们取其中的一个返回对象。在我的例子中，通过查看 `$result`，我注意到一个来自 "NetGear" 对象。接下来，我使用 `Where-Object` 来存取它。

在您的场景中，可用的对象明显不同，这取决于您网络中使用的设备，所以您需要调整过滤器表达式来匹配返回的对象之一。

```powershell
PS> $switch = $result | Where-Object ManufacturerName -like *NetGear*

PS> $switch


IsRootDevice     : True
RootDevice       : System.__ComObject
ParentDevice     :
HasChildren      : True
Children         : System.__ComObject
UniqueDeviceName : uuid:4d696e69-444c-164e-9d42-3894ed0e1db5
FriendlyName     : RBR50 (Gateway)
Type             : urn:schemas-upnp-org:device:InternetGatewayDevice:1
PresentationURL  : http://www.orbilogin.net/
ManufacturerName : NETGEAR, Inc.
ManufacturerURL  : http://www.netgear.com/
ModelName        : NETGEAR Orbi Desktop AC3000 Router
ModelNumber      : RBR50
Description      : http://www.netgear.com/home/products/wirelessrouters
ModelURL         : http://www.netgear.com/orbi
UPC              : RBR50
SerialNumber     : 5R21945T06DA4
Services         : System.__ComObject
```

大多数属性使用普通的数据类型，例如 string 或者 integer。例如，"UniqueDeviceName" 返回一个设备的唯一名称（稍后会变得很重要）。然而某些属性，只是返回 "System.__ComObject"。让我们看看这些：

每个 PnP 设备可以是一个链条的一部分，并且由一个根设备开始。由于我们一开始搜索的是根设备，所以 "RootDevice" 属性总是对应返回的对象：

```powershell
PS> $switch -eq $switch.RootDevice
True
```

要找出那些设备链接到根设备，请查看 "HasChildren" 和 "Children"："HasChildren" 是一个简单的 Boolean 值。然而 "Children" 是一个 "System.__ComObject" 对象并且包含了我们想了解的信息：

```powershell
PS> if ($switch.HasChildren) { $switch.Children.Count } else { 'no children' }
1
```

显然地，"Children" 看起来是某种数组。总之，一个根设备可以有许多子设备。通过存取该属性，PowerShell 自动将 "System.__ComObject" 转换为可读取的 .NET 对象，以下是我的 NetGear 设备的子设备：

```powershell
PS> $switch.Children


IsRootDevice     : False
RootDevice       : System.__ComObject
ParentDevice     : System.__ComObject
HasChildren      : True
Children         : System.__ComObject
UniqueDeviceName : uuid:4d696e69-444c-164e-9d43-3894ed0e1db5
FriendlyName     : WAN Device
Type             : urn:schemas-upnp-org:device:WANDevice:1
PresentationURL  :
ManufacturerName : NETGEAR
ManufacturerURL  : http://www.netgear.com/
ModelName        : NETGEAR Orbi Desktop AC3000 Router
ModelNumber      : RBR50
Description      : WAN Device on NETGEAR RBR50 Orbi Router
ModelURL         : http://www.netgear.com/
UPC              : RBR50
SerialNumber     : 5R21945T06DA4
Services         : System.__ComObject
```

这个子设备之下还有子设备。但是，继续深挖并列出子设备之下的子设备看起来失败了：

```powershell
PS> # works:
PS> $switch.Children | Select-Object HasChildren, Children

HasChildren Children
----------- --------
        True System.__ComObject



PS> # fails:
PS> $switch.Children.HasChildren
PS> $switch.Children.Children
PS> $switch.Children[0].HasChildren
Value does not fall within the expected range.
PS> $switch.Children[0].Children
Value does not fall within the expected range.
```

失败的原因是 COM 数组的一个特异性。它们使用一个非常规的枚举器，和普通的对象数组不同，所以 PowerShell 无法直接存取数组元素。一个简单的解决方案是使用 `ForEach-Object`：

```powershell
PS> $child = $switch.Children

PS> $child | ForEach-Object { $_.Children }


IsRootDevice     : False
RootDevice       : System.__ComObject
ParentDevice     : System.__ComObject
HasChildren      : False
Children         : System.__ComObject
UniqueDeviceName : uuid:4d696e69-444c-164e-9d44-3894ed0e1db5
FriendlyName     : WAN Connection Device
Type             : urn:schemas-upnp-org:device:WANConnectionDevice:1
PresentationURL  :
ManufacturerName : NETGEAR
ManufacturerURL  : http://www.netgear.com/
ModelName        : NETGEAR Orbi Desktop AC3000 Router
ModelNumber      : RBR50
Description      : WANConnectionDevice on NETGEAR RBR50 Orbi Router
ModelURL         : http://www.netgear.com/
UPC              : 606449084528
SerialNumber     : 5R21945T06DA4
Services         : System.__ComObject
```

同样地，也适用于 "ParentDevice" 和 `Services"。我们来查看我的 NetGear 设备的更多服务。这次，我希望直接存取我的 NetGear 设备（这样比枚举所有设备快得多）。不过您需要知道它的唯一设备名。在我的例子中，"UniqueDeviceName" 的值是 "uuid:4d696e69-444c-164e-9d42-3894ed0e1db5"：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
# the UDN is unique, so you need to find out the UDN for your device first
# you cannot use the UDN I used
$myNetgearSwitch = $UPnPFinder.FindByUDN('uuid:4d696e69-444c-164e-9d42-3894ed0e1db5')
$myNetgearSwitch
```

这次，几乎立即识别出我的设备。要列出它的服务，我只需要获取它的 "Services" 属性，并且 PowerShell 自动将该 COM 对象转为可见的属性：

```powershell
    PS> $myNetgearSwitch.Services

    ServiceTypeIdentifier                           Id                                   LastTransportStatus
    ---------------------                           --                                   -------------------
    urn:schemas-upnp-org:service:Layer3Forwarding:1 urn:upnp-org:serviceId:L3Forwarding1                   0
```

<!--本文国际来源：[Exploring Plug&amp;Play Devices (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-plug-play-devices-part-2)-->

