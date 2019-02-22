---
layout: post
date: 2018-04-27 00:00:00
title: "PowerShell 技能连载 - 允许远程处理"
description: PowerTip of the Day - Enabling Remoting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
cmdlet 有许多方法可以从另一台计算机远程获取信息。以下只是其中的一些方法：

```powershell
# try and connect to this computer
# (adjust it to a valid name in your network)
$destinationServer = "SERVER12"

# PowerShell remoting
$result1 = Invoke-Command { Get-Service } -ComputerName $destinationServer

# built-in
$result2 = Get-Service -ComputerName $destinationServer
$result3 = Get-Process -ComputerName $destinationServer
```

非常可能的情况是，缺省情况下远程访问不可用。受限，对于许多远程技术您需要目标端的管理员权限。但是即便您拥有该权限，客户操作系统的远程访问缺省情况下也是禁用的。

如果您希望在测试机上打开最常用的远程技术，请在用管理员权限打开的 PowerShell 中运行以下代码：

```powershell
netsh firewall set service remoteadmin enable
Enable-PSRemoting -SkipNetworkProfileCheck -Force
```

虽然第一条命令是已过时的，但仍然有效。它将管理员远程功能添加到防火墙例外中，允许基于 DCOM 的远程处理。第二行启用 PowerShell 远程处理。

<!--本文国际来源：[Enabling Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-remoting)-->
