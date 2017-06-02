---
layout: post
title: "PowerShell 技能连载 - 远程启动服务"
date: 2014-01-06 00:00:00
description: PowerTip of the Day - Starting Services Remotely
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
由于 `Start-Service` 命令没有 `-ComputerName` 参数，所以您无法简单地远程启动一个服务。然而您可以在一个 PowerShell 远程管理会话中运行 `Start-Service` 命令。在某些场景下，一个更简单的方法是使用 `Set-Service` 命令。以下代码可以在名为 Server12 的服务器上远程启动 Spooler 服务：

	Set-Service -Name Spooler -Status Running -ComputerName Server12

不幸的是，这个命令没有 `-Force` 开关。所以虽然您可以简单地启动服务，但您可能无法用这种方式停止它们。当一个服务依赖于另一个服务时，它必须使用“强制”的方式来停止。

<!--more-->
本文国际来源：[Starting Services Remotely](http://community.idera.com/powershell/powertips/b/tips/posts/starting-services-remotely)
