layout: post
title: "PowerShell 技能连载 - 担心隐藏的输入密码请求"
date: 2014-03-03 00:00:00
description: PowerTip of the Day - Beware Of Hidden Password Requests
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
您可以在任何主机上运行 PowerShell，powershell.exe 和 powershell_ise.exe 随着 Windows 发布。比起简单的 PowerShell 控制台，许多人更喜欢图形化的 ISE 编辑器。

一旦您开始使用控制台程序，您必须意识到 ISE 编辑器没有真实的控制台。在 ISE 编辑器中，任何时候一个控制台程序想要与您互动时，它将会运行失败。

所以 choice.exe 在控制台中工作正常，但是您在 ISE 编辑器中运行相同的命令时，却没有办法使 choice.exe 接收您的按键。

有些时候，这可能会导致意外的结果。当您在 ISE 编辑器中运行 driverquery.exe 加上 /S Servername 参数从远程系统中读取驱动器信息时，编辑器会假死。

当您在控制台中运行相同的命令时，您会知道原因：driverquery.exe 可能会显示一个提示并期望输入密码。ISE 编辑器无法处理这个提示和您的输入——由于它没有控制台缓冲区。

所以当您的脚本用到了控制台应用程序时，您最好在传统的 PowerShell 控制台中运行它们。

<!--more-->
本文国际来源：[Beware Of Hidden Password Requests](http://powershell.com/cs/blogs/tips/archive/2014/03/03/beware-of-hidden-password-requests.aspx)
