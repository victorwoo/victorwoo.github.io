---
layout: post
date: 2019-09-25 00:00:00
title: "PowerShell 技能连载 - 使用最新版的 PowerShell Core"
description: PowerTip of the Day - Playing with Latest PowerShell Core Version
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何下载一个 PowerShell 脚本，用来自动下载最新版的 PowerShell Core。

这个脚本支持一系列参数。默认情况下，它获取最新（稳定版）的生产版本。如果您希望使用包括预览版的最新版，请使用 `-Preview` 参数。并且，如果您希望使用 MSI 包安装它，请加上 `-MSI` 参数。

您不一定要将该脚本保存到文件。您可以直接执行下载脚本并通过 `Invoke-Expression` 执行它。不过，这个 cmdlet 被认为是有风险的，因为它直接执行您提交的任何代码，而没有机会让您事先检查代码。

以下是一行示例代码，用来下载最新版的 PowerShell Core MSI 安装包：

```powershell
Invoke-Expression -Command "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"
```

<!--本文国际来源：[Playing with Latest PowerShell Core Version](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/playing-with-latest-powershell-core-version)-->

