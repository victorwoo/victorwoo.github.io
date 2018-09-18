---
layout: post
date: 2018-08-15 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 功能（第 2 部分）"
description: PowerTip of the Day - Managing Windows Features (Part 2)
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
在 Windows 10 中，不像 Windows Server，您无法使用 `Get-WindowsFeature` 和 `Add-WindowsFeature` cmdlet 来管理 Windows 功能。

然而，对于客户端来说，有一个很类似的 cmdlet 可用：`Enable-WindowsOptionalFeature`。以下代码将添加 PowerShell Hyper-V cmdlet 和 Hyper-V 功能：

```powershell
Enable-WindowsOptionalFeature -Online -All -FeatureName Microsoft-Hyper-V-Management-PowerShell -NoRestart
Enable-WindowsOptionalFeature -Online -All -FeatureName Microsoft-Hyper-V -NoRestart
```

执行的结果是一个对象，告知您是否需要重启。

请注意 `-All` 参数：如果您忽略了该参数，那么您需要自行确保所有先决条件和依赖项都已安装好，才能添加另一个新项。如果您懒，或者不了解依赖项，那么 `-All` 参数将自动为您安装所有必须的依赖项。

<!--more-->
本文国际来源：[Managing Windows Features (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-windows-features-part-2)
