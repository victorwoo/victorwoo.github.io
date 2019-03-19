---
layout: post
date: 2019-01-29 00:00:00
title: "PowerShell 技能连载 - 将 Windows 服务器转变为工作站"
description: PowerTip of the Day - Turn a Windows Server into a Workstation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 5 及以上版本提供了一个自动添加 Windows 功能的 cmdlet，所以如果您正在运行 Windows Server 并且想使用 Workstation 功能，请以管理员权限打开一个 PowerShell，然后运行以下代码：

```powershell
Enable-WindowsOptionalFeature -FeatureName DesktopExperience -All -Online -NoRestart
```

<!--本文国际来源：[Turn a Windows Server into a Workstation](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turn-a-windows-server-into-a-workstation)-->
