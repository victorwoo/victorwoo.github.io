---
layout: post
date: 2021-11-23 00:00:00
title: "PowerShell 技能连载 - 启用 Active Directory cmdlet"
description: PowerTip of the Day - Enabling Active Directory Cmdlets
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在服务器和客户端上，Windows 都附带了 "ActiveDirectory" PowerShell 模块。它添加了许多 cmdlet 来管理 Active Directory 中的用户和资源。

默认情况下，该模块是隐藏的。要在客户端上启用它，请以管理员权限运行：

```powershell
$element = Get-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS*"
Add-WindowsCapability -Name $element.Name -Online
```

在服务器上，再次使用管理员权限并运行：

```powershell
Install-WindowsFeature RSAT-AD-PowerShell
Add-WindowsFeature RSAT-AD-PowerShell
```

<!--本文国际来源：[Enabling Active Directory Cmdlets](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/enabling-active-directory-cmdlets)-->

