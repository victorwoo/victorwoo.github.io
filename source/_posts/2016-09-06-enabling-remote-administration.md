---
layout: post
date: 2016-09-06 00:00:00
title: "PowerShell 技能连载 - 启用远程管理"
description: PowerTip of the Day - Enabling Remote Administration
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
*支持 PowerShell 2 以上版本*

许多早先基于 DCOM 的命令需要打开“远程管理防火墙例外”，才能访问远程系统。其中包含 `Get-WmiObject` 等 Cmdlet。

一个启用该功能的简单办法是在管理员权限下运行以下命令：

```shell
netsh firewall set service remoteadmin enable
```

虽然该命令已经准备淘汰，不过它仍然能用，而且是配置防火墙的最简单方法。

<!--more-->
本文国际来源：[Enabling Remote Administration](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-remote-administration)
