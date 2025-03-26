---
layout: post
date: 2023-06-08 00:00:51
title: "PowerShell 技能连载 - 测试驱动 PowerShellGet 版本 3"
description: PowerTip of the Day - Test-Driving PowerShellGet Version 3
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShellGet 是一个模块，包含重要的 cmdlet，比如 `Install-Module`，因此该模块实际上是下载和安装其他模块的先决条件，即从 powershellgallery.com 下载和安装模块的先决条件。

终于，期待已久的第 3 版该模块作为预览版在 PowerShell Gallery 中可用，有很多理由说明你应该使用这个新版本。

以下是安装步骤：

```powershell
PS> Install-Module -Name PowerShellGet -AllowPrerelease -Scope CurrentUser
```

你应该更新的一个原因是，你可能再也无法这样做了。很可能你的 `Install-Module` cmdlet 缺少 `-AllowPrerelease` 参数，因此无法安装任何预发布模块。对于任何使用语义版本的现代模块都是如此。

悲伤的事实是，PowerShellGet 在 Windows 10/11 映像中的初始版本 1.0.0.1 中被包含进去，并且从那时起从未自动更新。版本 1.0.0.1 现在已经过时，无法在许多情况下正常工作。

为了解决这个问题，你应该先手动强制安装 PowerShellGet 2.x。这将安装你安装 PowerShellGet 3.x 所需的先决条件：

```powershell
PS> Install-Module -Name PowerShellGet -Scope CurrentUser -Force -AllowClobber
```

运行这行命令并重新启动 PowerShell 后，`Install-Module` 应该具有 `-AllowPrelease` 参数，因此现在你可以运行第一个代码行并安装 PowerShellGet 3.x。

最终，PowerShellGet 3 版将希望解决所有这些问题，并为 PowerShell 的模块交换机制提供更强大的支持。
<!--本文国际来源：[Test-Driving PowerShellGet Version 3](https://blog.idera.com/database-tools/powershell/powertips/test-driving-powershellget-version-3/)-->

