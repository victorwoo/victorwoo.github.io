---
layout: post
date: 2018-05-28 00:00:00
title: "PowerShell 技能连载 - PowerShell 陈列架：探索脚本块日志（第 2 部分）"
description: 'PowerTip of the Day - PowerShell Gallery: Discovering Script Block Logging (Part 2)'
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
在前一个技能中我们介绍了免费的 `ScriptBlockLoggingAnalyzer`，它覆盖了 PowerShell 日志的代码。默认情况下，它只对一小部分命令有效，但如果您启用了所有脚本块的日志，那么您机器上任何人运行的任何代码都会被记录。

以下是操作步骤（只对 Windows PowerShell 有效，请在提升权限的 PowerShell 中运行！）：

```powershell
#requires -RunAsAdministrator

# install the module from the Gallery (only required once!)
Install-Module ScriptBlockLoggingAnalyzer -Force

# enable full script block logging
Enable-SBL

# extend the log size
Set-SBLLogSize -MaxSizeMB 100

# clear the log (optional)
Clear-SBLLog
```

现在起，这台机器上运行的所有 PowerShell 代码都会被记录。要查看记录的代码，请使用以下代码：

```powershell
PS> Get-SBLEvent | Out-GridView
```

<!--more-->
本文国际来源：[PowerShell Gallery: Discovering Script Block Logging (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-gallery-discovering-script-block-logging-part-2)
