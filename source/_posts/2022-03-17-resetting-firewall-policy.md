---
layout: post
date: 2022-03-17 00:00:00
title: "PowerShell 技能连载 - 复位防火墙策略"
description: PowerTip of the Day - Resetting Firewall Policy
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想在 Windows 10 或 11 上将防火墙规则恢复为出厂默认设置，请让 PowerShell 运行相应的 `netsh.exe` 命令：

```powershell
    PS> netsh advfirewall reset
```

需要提升权限的 PowerShell。该命令将撤消自安装操作系统以来您（或安装程序）对 Windows 防火墙所做的任何更改。

<!--本文国际来源：[Resetting Firewall Policy](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/resetting-firewall-policy)-->

