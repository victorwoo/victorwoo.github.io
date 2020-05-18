---
layout: post
date: 2020-04-22 00:00:00
title: "PowerShell 技能连载 - 检测是否连接到计费的 WLAN"
description: PowerTip of the Day - Testing for Metered WLAN
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否曾经需要知道您当前是否已连接到计费的网络？这是一种快速的检查方法：

```powershell
function Test-WlanMetered
{
  [void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
  $cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost()
  $cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted -or ($cost.NetworkCostType -ne "Unrestricted")
}
```

它使用一个 UWP API 返回有关网络状态的大量信息，包括有关网络是否计费的信息。

如果您使用的是较旧的 Windows 平台，则以下是替代的代码，该代码使用好用的旧版 "`netsh`" 命令行工具并提取所需的信息。请注意，字符串操作（下面的代码广泛使用）容易出错，可能需要进行调整。

同时，以下代码很好地说明了如果手头没有适当的面向对象的 API 可调用，那么 PowerShell 中的通用字符串操作工具如何可以用作最后的保障：

```powershell
function Test-WlanMetered
{
  $wlan = (netsh wlan show interfaces | select-string "SSID" | select-string -NotMatch "BSSID")
  if ($wlan) {
    $ssid = (($wlan) -split ":")[1].Trim() -replace '"'
    $cost = ((netsh wlan show profiles $ssid | select-string "Cost|Kosten") -split ":")[2].Trim() -replace '"'

    return ($cost -ne "unrestricted" -and $cost -ne "Uneingeschränkt" -and $cost -ne 'Uneingeschr"nkt')
  }
  else { $false }
}
```

<!--本文国际来源：[Testing for Metered WLAN](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/testing-for-metered-wlan)-->

