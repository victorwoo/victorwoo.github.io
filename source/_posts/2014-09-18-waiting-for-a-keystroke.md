---
layout: post
date: 2014-09-18 11:00:00
title: "PowerShell 技能连载 - 等待按键"
description: PowerTip of the Day - Waiting for a Keystroke
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
_适用于 PowerShell 所有版本，仅适用于 PowerShell 控制台_

若希望脚本执行结束时，保持 PowerShell 控制台程序为打开状态，您也许希望增加一句“按任意键继续”语句。以下是实现方式：

    Write-Host 'Press Any Key!' -NoNewline
    $null = [Console]::ReadKey('?') 

这段代码仅适用于真实的 PowerShell 控制台。它在 ISE 编辑器或其它未使用真实互操作键盘缓冲区的控制台程序中并不适用。

<!--more-->
本文国际来源：[Waiting for a Keystroke](http://community.idera.com/powershell/powertips/b/tips/posts/waiting-for-a-keystroke)
