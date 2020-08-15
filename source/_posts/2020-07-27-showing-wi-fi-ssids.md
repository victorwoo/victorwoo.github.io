---
layout: post
date: 2020-07-27 00:00:00
title: "PowerShell 技能连载 - 显示 Wi-Fi 的 SSID"
description: PowerTip of the Day - Showing Wi-Fi SSIDs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们说明了如何使用 netsh.exe 转储所有 Wi-Fi 配置名称。通常，配置名称和 SSID 是相同的。但是，如果您对真正的 Wi-Fi SSID 名称感兴趣，则可以通过转储单个配置文件并使用通配符作为配置文件名称来直接查询这些名称：

```powershell
PS> netsh wlan show profile name="*" key=clear |
 Where-Object { $_ -match "SSID name\s*:\s(.*)$"} |
 ForEach-Object { $matches[1].Replace('"','') }
```

<!--本文国际来源：[Showing Wi-Fi SSIDs](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/showing-wi-fi-ssids)-->

