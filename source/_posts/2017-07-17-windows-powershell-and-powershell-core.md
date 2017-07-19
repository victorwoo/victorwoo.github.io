---
layout: post
date: 2017-07-17 00:00:00
title: "PowerShell 技能连载 - Windows PowerShell 和 PowerShell Core"
description: PowerTip of the Day - Windows PowerShell and PowerShell Core
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
最近关于 PowerShell 版本有一些混淆。在 GitHub 上有一个名为 "PowerShell 6" 的[开源倡议](https://github.com/PowerShell/PowerShell)。

这是否意味着开源的 PowerShell 6 是 PowerShell 5 的继任者，并且最终和 Windows 一起发布？

并不是的。现在只有两个不同的 PowerShell，所谓的 "PowerShell Editions"。

"Windows PowerShell" 就我们所知会持续存在，并且将会随着将来的 Windows 版本发布，对应完整版 .NET Framework。

开源的 PowerShell 6 本意是基于 "PowerShell Core" 工作，这是一个有限的 .NET 子集 (.NET Core)。它的目的是在一个最小化的环境，例如 Nano Server 中运行，并且能够支持 Linux 和 Apple 等不同的平台。

从 PowerShell 5.1 开始，您可以这样检查 "PowerShell Edition"：

```powershell
PS> $PSVersionTable.PSEdition
Desktop
```

"Desktop" 表示您在完整的 .NET Framework 上运行 "Windows PowerShell"。"Core" 表示您在 .NET Core 上运行 "PowerShell Core"。

<!--more-->
本文国际来源：[Windows PowerShell and PowerShell Core](http://community.idera.com/powershell/powertips/b/tips/posts/windows-powershell-and-powershell-core)
