layout: post
title: "PowerShell 技能连载 - 在 Windows 8.1 中管理 Windows Defender"
date: 2013-12-24 00:00:00
description: PowerTip of the Day - Managing Windows Defender in Windows 8.1
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
Windows 8.1 发布了一个称为“Defender”的新模块。内置的 cmdlet 使您能够管理、查看和修改 Windows Defender 反病毒程序的每一个方面。

要列出所有可用的 cmdlet，请使用以下代码：

	Get-Command -Module Defender

如果您没有获得任何返回信息，那么您正在运行的很可能不是 Windows 8.1，所以该模块不可用。

下一步，试着浏览这些 cmdlet。例如 `Get-MpPreference`，将列出当前所有偏好设置。类似地，`Set-MpPreference` 可以改变它们的值。

`Get-MpThreatDetection` 将会列出当前检测到的所有威胁（如果当前没有任何威胁，则返回空）。

<!--more-->
本文国际来源：[Managing Windows Defender in Windows 8.1](http://community.idera.com/powershell/powertips/b/tips/posts/managing-windows-defender-in-windows-8-1)
