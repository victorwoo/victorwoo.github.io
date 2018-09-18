---
layout: post
date: 2018-09-05 00:00:00
title: "PowerShell 技能连载 - 管理 Lenovo BIOS 设置（第 3 部分）"
description: PowerTip of the Day - Managing Lenovo BIOS Settings (Part 3)
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
在前一个技能中我们介绍了如何在 PowerShell 中管理 Lenovo BIOS。通常，只需要管理单个设置。请注意某些操作需要管理员特权。

以下是转储所有可用设置名称的代码。请注意这些名字是大小写敏感的：

```powershell
$currentSetting = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi 
$currentSetting.CurrentSetting | 
    Where-Object { $_ } |
    ForEach-Object { $_.Split(',')[0] }
```

一旦您知道了想要操作的设置项的名称，就可以用这段代码来读取设置：

```powershell
$Settingname = "WakeOnLAN"

$currentSetting = Get-WmiObject -Class Lenovo_BiosSetting -Namespace root\wmi -Filter "CurrentSetting LIKE '%$SettingName%'"
$currentSetting.CurrentSetting  
```

以下代码转储某个指定设置的所有合法值：

```powershell
#requires -RunAsAdministrator

# this is case-sensitive
$Setting = "WakeOnLAN"

$selections = Get-WmiObject -Class Lenovo_GetBiosSelections -Namespace root\wmi
$selections.GetBiosSelections($Setting).Selections.Split(',')
```

以下是如何将一个设置改为一个新的值（例如，禁止 WakeOnLan）：

```powershell
#requires -RunAsAdministrator

$currentSetting = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi
$currentSetting.SetBiosSetting('WakeOnLAN,Disable').return

$SaveSettings = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi
$SaveSettings.SaveBiosSettings().return
```

<!--more-->
本文国际来源：[Managing Lenovo BIOS Settings (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-lenovo-bios-settings-part-3)
