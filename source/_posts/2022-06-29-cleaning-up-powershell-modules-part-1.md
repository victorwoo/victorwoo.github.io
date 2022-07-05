---
layout: post
date: 2022-06-29 00:00:00
title: "PowerShell 技能连载 - 清理 PowerShell 模块（第 1 部分）"
description: PowerTip of the Day - Cleaning Up PowerShell Modules (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有很多脚本可以通过转换一系列二进制值来读取注册表中原始的 Windows 10 产品密钥。

在这个迷你系列的第一部分中，我们将查看 PowerShell 保存其模块的位置，以及您可以采取什么措施删除不再需要的模块。

最安全的方法是完全专注于通过 `Install-Module` 安装的模块，因为这样您永远不会意外删除 Windows 或属于其他软件产品的一部分的模块。

这行代码列出了由 `Install-Module` 安装的所有模块，并让您选择要（永久）删除的模块。

```powershell
  Get-InstalledModule | 
    Out-GridView -Title 'Select module(s) to permanently delete' -PassThru |
    Out-GridView -Title 'Do you REALLY want to remove the modules below? CTRL+A and OK to confirm' -PassThru |
    Uninstall-Module
```

注意：如果模块安装在 "AllUsers" 范围中，则可能需要管理员特权。

注意：删除模块时，它将从硬盘驱动器中永久删除。确保您知道它发布了哪些 cmdlet，并且确信不再需要它们。如果您不小心删除了模块，则可以随时通过 `Install-Module` 重新安装它。

<!--本文国际来源：[Cleaning Up PowerShell Modules (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-up-powershell-modules-part-1)-->

