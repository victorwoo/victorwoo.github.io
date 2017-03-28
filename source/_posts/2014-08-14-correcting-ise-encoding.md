layout: post
date: 2014-08-14 11:00:00
title: "PowerShell 技能连载 - 修正 ISE 的编码"
description: PowerTip of the Day - Correcting ISE Encoding
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
_适用于所有 PowerShell 版本_

当您在 ISE 编辑器中运行一个控制台程序时，非标准字符，例如“ä”或“ß”将会显示不正常。要修正 ISE 和隐藏的控制台之间通信的编码，请使用这段代码：

    # Repair encoding. This REQUIRES a console app to run first because only
    # then will ISE actually create its hidden background console
    
    $null = cmd.exe /c echo
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    
    # Now all is fine
    
    cmd.exe /c echo ÄÖÜäöüß

<!--more-->
本文国际来源：[Correcting ISE Encoding](http://community.idera.com/powershell/powertips/b/tips/posts/correcting-ise-encoding)
