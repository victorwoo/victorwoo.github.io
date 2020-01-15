---
layout: post
date: 2020-01-07 00:00:00
title: "PowerShell 技能连载 - 探索即插即用设备（第 4 部分）"
description: PowerTip of the Day - Exploring Plug&amp;Play Devices (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能中，我们研究了 `UPnP.UPnPDeviceFinder` 以及如何识别网络中的设备。让我们看一些用例。显然，这些用例是您的灵感来源，因为您可以做的事情完全取决于连接到网络的实际设备。

我的第一个用例是管理 NAS 设备，名为 Synology Disk Station。可以通过 WEB 界面进行管理，但我总是会忘记 URL，当然 URL 和端口会根据配置而有所不同。

这是一种搜索任何磁盘站并自动打开其 Web 界面的方法。由于所有连接数据都是从设备中检索的，因此即使 IP 地址更改或您配置了别的端口，此操作也仍然有效。

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("ssdp:all", 0) |
Where-Object ManufacturerName -eq 'Synology' |
Select-Object -ExpandProperty PresentationUrl |
ForEach-Object { Start-Process -FilePath $_ }
```

注意：如果您没有 Synology 磁盘站，请查看您拥有的其他设备。只需查看 `FindByType()` 返回的数据，然后根据需要定制 `Where-Object`。


由于该代码枚举了所有 UPnP 设备，因此需要 10 到 20 秒。如果要加快处理速度，可以找出所用设备的 UDN（唯一名称），以后再使用这些 UDN：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("ssdp:all", 0) |
Where-Object ManufacturerName -eq 'Synology' |
Select-Object -ExpandProperty UniqueDeviceName
```

UDNs are unique and differ per device, so this approach just makes sense if you need to access the same device over and over again. In my case, the UDN was uuid:7379AA6F-6473-6D00-0000-001132283f5e, and opening the web interface now worked much faster:
UDN 是唯一的，并且因设备而异，因此，如果您需要多次访问同一设备，则此方法才有意义。在我的情况下，UDN 是 uuid:7379AA6F-6473-6D00-0000-001132283f5e，现在打开 Web 界面的速度要快得多：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("uuid:7379AA6F-6473-6D00-0000-001132283f5e", 0) |
Select-Object -ExpandProperty PresentationUrl |
Foreach-Object { Start-Process -FilePath $_ }
```

这引出了我的第二个使用场景：我正在使用 Philips Hue 系统管理家里的灯光。飞利浦提供了丰富的 REST API 来实现自动化。您所需要的是网桥的 IP 地址。

This will find the IP addresses of any Philips Hue bridge in your local network:
这段代码将列出本地网络中所有 Philips Hue 网桥的 IP 地址：

``powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("upnp:rootdevice", 0) |
Where-Object Description -like 'Philips hue*' |
Select-Object -ExpandProperty FriendlyName |
ForEach-Object {
    if ($_ -match '(?\w*).*?\((?.*)\)')
    {
    $null = $matches.Remove(0)
    [PSCustomObject]$matches
    }
    }
```

该代码查找根设备，其描述以 "Philips hue" 开头的根设备，然后使用正则表达式拆分 "FriendlyName" 属性的内容并返回网桥名称及其 IP 地址。

就我而言，结果如下所示：

    IP            BridgeName
    --            ----------
    192.168.22.10 BridgeOne
    192.168.23.16 BridgeWork

<!--本文国际来源：[Exploring Plug&amp;Play Devices (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-plug-play-devices-part-4)-->

