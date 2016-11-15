layout: post
date: 2016-11-01 16:00:00
title: "PowerShell 技能连载 - 用一行代码更新 PowerShell 帮助信息"
description: PowerTip of the Day - Updating PowerShell Help with One-Liner
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
要获得 PowerShell 最全的输出信息，您需要更新 PowerShell 的帮助至少一次。这将下载并安装当您通过 cmdlet 运行 `Get-Help` 或是在 PowerShell ISE 中点击一个 cmdlet 并按 F1 时将出现的基础帮助文件集。

更新 PowerShell 帮助需要 Administrator 特权，因为帮助文件存在 Windows 文件夹中。

以下是一个单行命令，演示了如何以管理员特权运行任何 PowerShell 命令。这个命令将更新本地的 PowerShell 帮助文件：

```powershell
Start-Process -FilePath powershell -Verb RunAs -ArgumentList "-noprofile -command Update-Help -UICulture en-us  -Force"
```

<!--more-->
本文国际来源：[Updating PowerShell Help with One-Liner](http://community.idera.com/powershell/powertips/b/tips/posts/updating-powershell-help-with-one-liner)
