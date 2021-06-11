---
layout: post
date: 2021-05-07 00:00:00
title: "PowerShell 技能连载 - 检测 Wi-Fi 信号强度（第 3 部分）"
description: PowerTip of the Day - Identifying Wi-Fi Signal Strength (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们介绍了免费的 PowerShell 模块 Get-WLANs ，该模块可以访问 Windows Wi-Fi 框架并返回信息，例如信号强度。这是下载并安装它的命令：

```powershell
Install-Module -Name Get-WLANs -Scope CurrentUser -Force
```

尽管您可以简单地使用其新命令 Get-WLANs（如上一技巧中所述），但该模块还添加了一个新的 .NET 类型，您可以在运行该命令后使用它。首先运行此命令以初始化新的 .NET 类型：

```powershell
# "initialize" the new type
$null = Get-WLANs
```

接下来，创建一个原生的 "WlanClient" 对象：

```powershell
$wc = [NativeWifi.WlanClient]::New()
```

现在，您可以转储有关系统中所有可用的 Wi-Fi 适配器的所有技术细节：

```powershell
PS> $wc.Interfaces


Autoconf             : True
BssType              : Any
InterfaceState       : Connected
Channel              : 36
RSSI                 : 29
RadioState           : NativeWifi.Wlan+WlanRadioState
CurrentOperationMode : ExtensibleStation
CurrentConnection    : NativeWifi.Wlan+WlanConnectionAttributes
NetworkInterface     : System.Net.NetworkInformation.SystemNetworkInterface
InterfaceGuid        : 7d6c33b7-0354-4ad7-a72f-5a1a5cbb1a9b
InterfaceDescription : Killer(R) Wi-Fi 6 AX1650s 160MHz Wireless Network Adapter (201D2W)
InterfaceName        : WLAN
```

"`Interfaces`" 属性返回一个数组，因此您的第一个 Wi-Fi 适配器由以下形式表示：

```powershell
$wc.Interfaces[0]
```

它提供了很多方法，例如，检索可访问的可用 Wi-Fi 网络列表。这将扫描新的网络：

```powershell
$wc.Interfaces[0].Scan()
Start-Sleep -Seconds 1
```

以下代码转储可使用的网络列表（包括信号强度，频率和信道）：

```powershell
PS> $wc.Interfaces[0].GetAvailableNetworkList(3)


Dot11PhyTypes               : {8}
profileName                 : internetcafe
dot11Ssid                   : NativeWifi.Wlan+Dot11Ssid
dot11BssType                : Infrastructure
numberOfBssids              : 3
networkConnectable          : True
wlanNotConnectableReason    : Success
morePhyTypes                : False
wlanSignalQuality           : 81
securityEnabled             : True
dot11DefaultAuthAlgorithm   : RSNA_PSK
dot11DefaultCipherAlgorithm : CCMP
flags                       : Connected, HasProfile

(...)
```

此对象模型为提供了丰富的方法和属性来控制和管理 Wi-Fi 网络适配器。例如，此代码转储可用的 SSID 列表及其信号强度：

```powershell
$ssid = @{
    N='SSID'
    E={ [System.Text.Encoding]::Ascii.GetString( $_.dot11ssid.SSID,
                                                0,
                                                $_.dot11ssid.SSIDLength )
    }
}

$wc.Interfaces[0].GetAvailableNetworkList(3) |
    Select-Object -Property $ssid, wlanSignalQuality, profileName |
    Where-Object SSID
```

结果看起来类似这样：

    SSID                       wlanSignalQuality profileName
    ----                       ----------------- -----------
    internetcafe                              81 internetcafe
    internetcafe                              87 internetcafe 2
    internetcafe                              87
    DIRECT-fb-HP M477 LaserJet                31
    Guest                                     67

<!--本文国际来源：[Identifying Wi-Fi Signal Strength (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-wi-fi-signal-strength-part-3)-->

