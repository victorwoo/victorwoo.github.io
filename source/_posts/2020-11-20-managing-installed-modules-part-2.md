---
layout: post
date: 2020-11-20 00:00:00
title: "PowerShell 技能连载 - 管理已安装的模块（第 2 部分）"
description: PowerTip of the Day - Managing Installed Modules (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
每当您通过 `Install-Module` 安装新模块或通过 `Update-Module` 更新现有模块时，新模块版本就会并行地安装。

如果您始终使用最新版本的模块，而无需访问特定的旧版本，则可能需要查找过时的模块并将其删除：

```powershell
# get all installed modules as a hash table
# each key holds all versions of a given module
$list = Get-InstalledModule |
Get-InstalledModule -AllVersions |
Group-Object -Property Name -AsHashTable -AsString

# take all module names...
$list.Keys |
  ForEach-Object {
    # dump all present versions...
    $list[$_] |
    # sort by version descending (newest first)
    Sort-Object -Property Version -Descending |
    # and skip newest, returning all other
    Select-Object -Skip 1
} |
# remove outdated (check whether you really don't need them anymore)
Uninstall-Module -WhatIf
```

<!--本文国际来源：[Managing Installed Modules (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-installed-modules-part-2)-->

