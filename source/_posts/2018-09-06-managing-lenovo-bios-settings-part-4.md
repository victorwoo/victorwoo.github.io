---
layout: post
date: 2018-09-06 00:00:00
title: "PowerShell 技能连载 - 管理 Lenovo BIOS 设置（第 4 部分）"
description: PowerTip of the Day - Managing Lenovo BIOS Settings (Part 4)
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
在前一个技能中我们演示了如何读取和改变 Lenovo 计算机的 BIOS 设置。例如，以下代码禁止 WakeOnLan：

```powershell
#requires -RunAsAdministrator  

$currentSetting = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi
$currentSetting.SetBiosSetting('WakeOnLAN,Disable').return
    
$SaveSettings = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi
$SaveSettings.SaveBiosSettings().return
```

如果某个 BIOS 设置是被密码保护的，以下代码演示如何更改一个受 BIOS 密码保护的设置：

```powershell
#requires -RunAsAdministrator
$BIOSPassword = "topSecret"
    
$currentSetting = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi
$currentSetting.SetBiosSetting("WakeOnLAN,Disable,$BIOSPassword,ascii,us").return
    
$SaveSettings = Get-WmiObject -Class Lenovo_SaveBiosSettings -Namespace root\wmi
$SaveSettings.SaveBiosSettings("$BIOSPassword,ascii,us").return
```

请注意该密码仅在该设置项受 BIOS 密码保护的情况下生效。如果实际中没有密码而您输入了密码，它并不会被验证，而且改动会生效。

<!--more-->
本文国际来源：[Managing Lenovo BIOS Settings (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-lenovo-bios-settings-part-4)
