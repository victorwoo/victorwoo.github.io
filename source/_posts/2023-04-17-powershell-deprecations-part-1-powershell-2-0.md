---
layout: post
date: 2023-04-17 00:00:16
title: "PowerShell 技能连载 - PowerShell 废弃功能 (第 1 部分：PowerShell 2.0)"
description: 'PowerTip of the Day - PowerShell Deprecations (Part 1: PowerShell 2.0)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows PowerShell 2.0 仍然是任何 Windows PowerShell 的一部分，用于向后兼容。当启用时，它是一个严重的安全风险 - PowerShell 2.0 简单地没有 PowerShell 5 及更高版本中发现的所有先进恶意软件检测工具。

如果您拥有管理员权限，则此行将告诉您系统上是否启用了 PowerShell 2.0：

```powershell
PS> Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2
```

如果它已启用，请确保将其禁用。
<!--本文国际来源：[PowerShell Deprecations (Part 1: PowerShell 2.0)](https://blog.idera.com/database-tools/powershell/powertips/powershell-deprecations-part-1-powershell-2-0/)-->

