---
layout: post
date: 2022-07-05 00:00:00
title: "PowerShell 技能连载 - 清理 PowerShell 模块（第 3 部分）"
description: PowerTip of the Day - Cleaning Up PowerShell Modules (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在第一部分和第二部分中，我们全面学习了如何删除 PowerShell 模块。在这最后一部分中，我们将研究您可能不再需要的 PowerShell 模块版本。

每当将 PowerShell 模块更新为新版本时，新版本就可以与所有旧版本并行保存。这个设计方式很聪明，因为这可以方便您更新模块，即使它们当前正在使用。

然而，这种设计也导致了越来越多的垃圾。除非您无需明确地退回到旧版本的模块，否则通常只需要最新版本的模块。

这就是为什么下面的脚本列出模块的多个可用版本，然后让用户决定应清理哪一个：

```powershell
# script may require Administrator privileges if you want to remove
# module versions installed in "AllUsers" scope


# find ALL modules with more than one version and/or location:
$multiversion = Get-Module -ListAvailable |
  Group-Object -Property Name |
  Sort-Object -Property Name |
  Where-Object Count -gt 1

# ask user WHICH of these modules to clean?
$clean = $multiversion |
    Select-Object -Property @{N='Versions';E={$_.Count}}, @{N='ModuleName';E={$_.Name}} |
    Out-GridView -Title 'Select module(s) to clean' -PassThru

# get the todo list with the modules the user wants to clean:
$todo = $multiversion | Where-Object Name -in $clean.ModuleName

$todo |
  ForEach-Object {
    $module = $_.Name
    # list all versions of a given module and let the user decide which versions
    # to keep and which to remove:
    $_.Group |
        Select-Object -Property Version, ModuleBase, ReleaseNotes |
        Sort-Object -Property Version |
        Out-GridView -Title "Module $module : Select all versions that you want to remove" -PassThru |
        Select-Object -ExpandProperty ModuleBase |
        # do a last confirmation dialog before permanently deleting the subversions:
        Out-GridView -Title 'Do you really want to permanently delete these folders? CTRL+A and OK to confirm' -PassThru  |
        Remove-Item -Recurse -Force

  }
```

一旦用户选择一个或多个模块要清理，脚本一次会处理一个模块，并列出其所有版本。然后，用户可以选择要删除的版本。

请注意，您可能需要管理员特权才能删除 "AllUsers" 范围中安装的模块版本。
<!--本文国际来源：[Cleaning Up PowerShell Modules (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-up-powershell-modules-part-3)-->

