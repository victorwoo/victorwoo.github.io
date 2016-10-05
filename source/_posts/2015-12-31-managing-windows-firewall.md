layout: post
date: 2015-12-31 12:00:00
title: "PowerShell 技能连载 - 管理 Windows 防火墙"
description: PowerTip of the Day - Managing Windows Firewall
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
从 Windows 8 和 Server 2012 开始，有一个 Cmdlet 可以在多个配置中启用客户端防火墙：

```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

在之前的操作系统中，您需要使用依靠 netsh.exe：

```powershell
netsh advfirewall set allprofiles state on
```

<!--more-->
本文国际来源：[Managing Windows Firewall](http://powershell.com/cs/blogs/tips/archive/2015/12/31/managing-windows-firewall.aspx)
