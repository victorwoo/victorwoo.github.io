---
layout: post
date: 2022-07-01 00:00:00
title: "PowerShell 技能连载 - 清理 PowerShell 模块（第 2 部分）"
description: PowerTip of the Day - Cleaning Up PowerShell Modules (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在第一部分中，我们研究了如何删除通过 "`Install-Module`" 安装的 PowerShell 模块。如果您不再需要它们，则可以手动删除这些 PowerShell 模块。毕竟它们只是文件夹。

这段的代码列出了所有可用的 PowerShell 模块，并让您选择要删除的模块。

```powershell
# folders where PowerShell looks for modules:
$paths = $env:PSModulePath -split ';'
# finding actual module folders
$modules = Get-ChildItem -Path $paths -Depth 0 -Directory | Sort-Object -Property Name

$modules | 
  Select-Object -Property Name, @{N='Parent';E={$_.Parent.FullName}}, FullName |
  Out-GridView -Title 'Select module(s) to permanently delete' -PassThru |
  Out-GridView -Title 'Do you REALLY want to remove the modules below? CTRL+A and OK to confirm' -PassThru |
  Remove-Item -Path { $_.FullName } -Recurse -Force -WhatIf # remove -WhatIf to actually delete (as always at own risk)
```

注意：如果模块安装在 "AllUsers" 范围中，则可能需要管理员特权。

注意：删除模块时，它将从硬盘驱动器中永久删除。确保您知道它发布了哪些 cmdlet，并且确信不再需要它们。
<!--本文国际来源：[Cleaning Up PowerShell Modules (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-up-powershell-modules-part-2)-->

