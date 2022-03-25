---
layout: post
date: 2022-03-21 00:00:00
title: "PowerShell 技能连载 - Defender: 清空威胁列表和相关设置"
description: 'PowerTip of the Day - Defender: Purge Threat List and related Settings'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
默认情况下，Windows Defender 会在 15 天后自动清除它识别为威胁的项目。可以使用 PowerShell 直接配置此首选项以及许多其他首选项。只需确保启动提升权限的 PowerShell。

此示例查询清除间隔，然后设置新的清除时间间隔并对其进行验证：

```powershell
    PS> (Get-MpPreference).ScanPurgeItemsAfterDelay
    15

    PS> Set-MpPreference -ScanPurgeItemsAfterDelay 10

    PS> (Get-MpPreference).ScanPurgeItemsAfterDelay
    10
```

<!--本文国际来源：[Defender: Purge Threat List and related Settings](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/defender-purge-threat-list-and-related-settings)-->

