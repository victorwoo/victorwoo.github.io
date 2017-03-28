layout: post
title: "PowerShell 技能连载 - 启用传统远程控制"
date: 2014-03-31 00:00:00
description: PowerTip of the Day - Enabling Classic Remoting
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
许多 cmdlet 有内置的远程功能，例如 `Get-Service` 和 `Get-Process` 都具有 `-ComputerName` 参数，同样的还有 `Get-WmiObject`。

然而，要真正地远程使用这些 cmdlet，还需要一些先决条件。多数使用传统远程技术的 cmdlet 需要在目标机器上启用“远程管理”防火墙规则。它允许 DCOM 通信。还有一些需要目标计算机运行远程注册表服务。

所以在多数场景中，当您拥有目标机器的管理员，并且运行以下命令，则管理员可以通过传统远程 cmdlet 访问目标机器：

![](/img/2014-03-31-enabling-classic-remoting-001.png)

注意新版的 Windows 中 `netsh firewall` 命令可能会被废弃，不过目前仍然可以用。该命令比新版的 `netsh advfirewall` 命令用起来更简单。

<!--more-->
本文国际来源：[Enabling Classic Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-classic-remoting)
