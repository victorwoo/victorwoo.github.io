---
layout: post
date: 2021-12-03 00:00:00
title: "PowerShell 技能连载 - 检测挂起的重启"
description: PowerTip of the Day - Check for Pending Reboot
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
下面的代码检测是否有挂起的重启：

```powershell
$rebootRequired = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
"Pending reboot: $rebootRequired"
```

<!--本文国际来源：[Check for Pending Reboot](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/check-for-pending-reboot)-->

