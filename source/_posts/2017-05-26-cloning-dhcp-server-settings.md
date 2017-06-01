layout: post
date: 2017-05-26 00:00:00
title: "PowerShell 技能连载 - 克隆 DHCP 服务器设置"
description: PowerTip of the Day - Cloning DHCP Server Settings
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
从 Windows Server 2012 开市，您可以快速地导出和重新导入 DHCP 设置。克隆或迁移 DHCP 服务器是通过快照的形式。以下的例子从 \\ORIGDHCP 导出设置并导入本地的 DHCP 服务器中：

```powershell
Export-DHCPServer -File "$env:temp\dhcpsettings.xml" -Computername ORIGDHCP
Import-DHCPServer -File "$env:temp\dhcpsettings.xml"
```

<!--more-->
本文国际来源：[Cloning DHCP Server Settings](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-dhcp-server-settings)
