---
layout: post
date: 2018-09-26 00:00:00
title: "PowerShell 技能连载 - 启用脚本块日志"
description: PowerTip of the Day - Enabling Script Block Logging
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们深入了解了 PowerShell 5 脚本块日志的工作方式：简而言之，启用了以后，机器上运行的所有 PowerShell 代码在机器上的执行过程都将记录日志，这样您可以浏览源代码并查看机器上运行了什么 PowerShell 代码。

我们将它封装为一个免费的 PowerShell 模块，可以从 PowerShell Gallery 上下载，所以要启用脚本块日志，您只需要一个以管理员特权运行的 PowerShell 5.x 控制台，以及以下代码：

```powershell
Install-Module -Name scriptblocklogginganalyzer -Scope CurrentUser
Set-SBLLogSize -MaxSizeMB 1000
Enable-SBL
```

一旦启用了脚本块日志，您可以转储日志并且像这样查看记录的脚本代码：

```powershell
Get-SBLEvent | Out-GridView
```

<!--本文国际来源：[Enabling Script Block Logging](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-script-block-logging)-->
