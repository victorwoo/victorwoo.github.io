---
layout: post
date: 2019-12-30 00:00:00
title: "PowerShell 技能连载 - 探索即插即用设备（第 1 部分）"
description: PowerTip of the Day - Exploring Plug&amp;Play Devices (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可能已经生活在一个互联的智能家居，许多设备连接到您的网络。PowerShell 只需几行代码就可以帮助您找到您的设备：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("upnp:rootdevice", 0)
```

请注意 UPnP 查找器组件需要一些时间来检测您的设备。结果看起来类似这样：

    IsRootDevice     : True
    RootDevice       : System.__ComObject
    ParentDevice     :
    HasChildren      : False
    Children         : System.__ComObject
    UniqueDeviceName : uuid:73796E6F-6473-6D00-0000-001132283f5e
    FriendlyName     : Storage2 (DS414)
    Type             : urn:schemas-upnp-org:device:Basic:1
    PresentationURL  : http://192.168.2.107:5000/
    ManufacturerName : Synology
    ManufacturerURL  : http://www.synology.com/
    ModelName        : DS414
    ModelNumber      : DS414 5.1-5055
    Description      : Synology NAS
    ModelURL         : http://www.synology.com/
    UPC              :
    SerialNumber     : 001132283f5e
    Services         : System.__ComObject

    IsRootDevice     : True
    RootDevice       : System.__ComObject
    ParentDevice     :
    HasChildren      : False
    Children         : System.__ComObject
    UniqueDeviceName : uuid:2f402f80-da50-11e1-9b23-001788ac0af1
    FriendlyName     : BridgeOne (192.168.2.100)
    Type             : urn:schemas-upnp-org:device:Basic:1
    PresentationURL  : http://192.168.2.100/index.html
    ManufacturerName : Signify
    ManufacturerURL  : http://www.meethue.com/
    ModelName        : Philips hue bridge 2015
    ModelNumber      : BSB002
    Description      : Philips hue Personal Wireless Lighting
    ModelURL         : http://www.meethue.com/
    UPC              :
    SerialNumber     : 001788ac0af1
    Services         : System.__ComObject
    ...

使用 `Select-Object` 来选择您感兴趣的属性：

```powershell
$UPnPFinder = New-Object -ComObject UPnP.UPnPDeviceFinder
$UPnPFinder.FindByType("upnp:rootdevice", 0) |
    Select-Object ModelName, FriendlyName, PresentationUrl |
    Sort-Object ModelName
```

在我的家中，该列表看起来类似这样：

    ModelName                          FriendlyName               PresentationURL
    ---------                          ------------               ---------------
    AFTMM                              Tobias's 2nd Fire TV
    AFTS                               Tobias's Fire TV
    AFTT                               Tobias's 3rd Fire TV stick
    DS414                              Storage2 (DS414)           http://192.168.2.107:5000/
    NETGEAR Orbi Desktop AC3000 Router RBR50 (Gateway)            http://www.orbilogin.net/
    Philips hue bridge 2015            BridgeOne (192.168.2.100)  http://192.168.2.100/index.html
    Philips hue bridge 2015            BridgeWork (192.168.2.106) http://192.168.2.106/index.html
    SoundTouch 20                      Bad
    SoundTouch 30                      Portable
    SoundTouch SA-4                    Garden
    SoundTouch SA-4                    LivingRoom

我正在使用群晖 NAS，假设我忘了访问它的 URL，那么现在可以快速地找回它。我的飞利浦灯光系统也是这样：UPnP 查找器返回所有 hub 的 IP 地址。

请注意 UPnP 查找器只能返回和您的计算机连入相同网络的设备。如果您的设备 IP 地址是在其它子网，那么不能通过这种方式检测。

<!--本文国际来源：[Exploring Plug&amp;Play Devices (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/exploring-plug-play-devices-part-1)-->

