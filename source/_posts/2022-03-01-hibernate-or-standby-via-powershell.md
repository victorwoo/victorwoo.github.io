---
layout: post
date: 2022-03-01 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 休眠或待机"
description: PowerTip of the Day - Hibernate or Standby via PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们说明了虽然很难直接访问 Windows 电源管理 API，但还有其他 API 可以为您做到这一点。这段代码可让您将 Windows 系统关闭到所需的电源管理状态，即您可以将其休眠并使其进入无能耗状态：

```powershell
# use the built-in pwmgmt support in Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# define the power status you want to enable
$PowerState = [System.Windows.Forms.PowerState]::Hibernate

# allow or refuse force to be applied
$Force = $false

# turn off wake off capabilities as well
$DisableWake = $false

# apply the setting:
[System.Windows.Forms.Application]::SetSuspendState($PowerState, $Force, $DisableWake)
```

<!--本文国际来源：[Hibernate or Standby via PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hibernate-or-standby-via-powershell)-->

