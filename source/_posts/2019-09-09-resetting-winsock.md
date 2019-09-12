---
layout: post
date: 2019-09-09 00:00:00
title: "PowerShell 技能连载 - 重设 Winsock"
description: PowerTip of the Day - Resetting Winsock
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 既可以运行内置的 PowerShell 命令，也可以运行常规的控制台命令，所以继续用控制台命令处理已知的任务也不是件坏事。

例如，如果您希望重设 winsock，以下是一个可信赖的解决方案：

```powershell
#requires -RunAsAdministrator

netsh winsock reset
netsh int ip reset
```

请注意这段代码需要管理员特权，并且可能需要重启才能生效。

<!--本文国际来源：[Resetting Winsock](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/resetting-winsock)-->

