---
layout: post
date: 2020-01-27 00:00:00
title: "PowerShell 技能连载 - 在 Windows PowerShell 和 PowerShell Core 中共享模块"
description: PowerTip of the Day - Sharing Modules in Windows PowerShell and PowerShell Core
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
许多 PowerShell 用户开始研究 PowerShell 7，并与内置的 Windows PowerShell 并行运行。

两个 PowerShell 版本都在自己的位置维护各自的 PowerShell 模块。因此当您添加新模块（即通过 `Install-Module`）时，需要分别对两个版本的 PowerShell 执行此操作。

不过 Windows PowerShell 和 PowerShell 7 共享同一个文件夹路径：尽管是 Windows PowerShell 引入了该目录，但 PowerShell 7 也会检查此文件夹并自动加载位于其中的模块：

    C:\Program Files\WindowsPowerShell\Modules

要在两个 PowerShell 版本中同时使用某个模块，请确保将模块复制到此文件夹。使用 `Install-Module` 时，请使用 `-Scope AllUsers`（或忽略整个参数）。

由于该文件夹影响所有用户，因此该文件夹受到保护，并且您需要管理员权限才能向其中添加模块。

请注意，PowerShell 还会在另外一个路径中查找模块：

    C:\Windows\system32\WindowsPowerShell\v1.0\Modules

这是所有 Microsoft 模块所在的位置。该路径也会和 PowerShell 7 共享。

<!--本文国际来源：[Sharing Modules in Windows PowerShell and PowerShell Core](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/sharing-modules-in-windows-powershell-and-powershell-core)-->

