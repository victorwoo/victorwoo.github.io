layout: post
date: 2015-03-31 11:00:00
title: "PowerShell 技能连载 - ISE 自动完成技巧"
description: PowerTip of the Day - ISE Auto-Completion Trick
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
_适用于 PowerShell 3.0 ISE 及以上版本_

当您希望选择某个 cmdlet 返回的信息时，通常使用的是 `Select-Object`：

    Get-Process | Select-Object -Property Name, Company, Description

然而，您需要手工键入希望显示的属性名。当您键入“`-Property`”之后并不会弹出智能提示。

一个不为人知的技巧是按下 `CTRL+SPACE` 来手动显示智能提示菜单。如您所见，PowerShell 会开心地提供所有属性的列表，前提是上一级的 cmdlet 定义了输出的类型。

要选择多余一个属性，在键入逗号之后，再次按下 `CTRL+SPACE` 即可。

<!--more-->
本文国际来源：[ISE Auto-Completion Trick](http://community.idera.com/powershell/powertips/b/tips/posts/ise-auto-completion-trick)
