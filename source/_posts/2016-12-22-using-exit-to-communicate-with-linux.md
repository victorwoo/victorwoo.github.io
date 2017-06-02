---
layout: post
date: 2016-12-22 00:00:00
title: "PowerShell 技能连载 - 使用“Exit”和 Linux 通信"
description: "PowerTip of the Day - Using “Exit” to Communicate with Linux"
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
当一个 PowerShell 脚本结束时，您可以使用“`Exit`”命令来返回一个数值。这在 Windows 世界中是一个很好的实践。它能够设置“Error Level”值，并能够被调用者（例如一个批处理文件或是定时任务管理器）读取到。

```powershell
exit 99    
```
既然 PowerShell 在 Linux 上也可以运行，它也可以用来报告调用 Linux 进程的状态值。

<!--more-->
本文国际来源：[Using “Exit” to Communicate with Linux](http://community.idera.com/powershell/powertips/b/tips/posts/using-exit-to-communicate-with-linux)
