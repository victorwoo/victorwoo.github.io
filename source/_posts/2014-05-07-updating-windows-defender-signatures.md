layout: post
title: "PowerShell 技能连载 - 更新 Windows Defender 病毒定义"
date: 2014-05-07 00:00:00
description: PowerTip of the Day - Updating Windows Defender Signatures
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
Windows 8.1 带来了一系列新的 cmdlet。其中一个可以自动下载并安装 Windows Defender 最新的反病毒定义。

![](/img/2014-05-07-updating-windows-defender-signatures-001.png)

`Get-MpComputerStatus` 返回当前病毒定义的信息。

这些 cmdlet 不是 PowerShell 的一部分，而是 Windows 8.1 的一部分，所以在早期版本的操作系统中，您会碰到找不到命令的错误信息。

<!--more-->
本文国际来源：[Updating Windows Defender Signatures](http://community.idera.com/powershell/powertips/b/tips/posts/updating-windows-defender-signatures)
