---
layout: post
date: 2022-06-27 00:00:00
title: "PowerShell 技能连载 - 快速查找过期的 PowerShell 模块"
description: PowerTip of the Day - Quickly Finding Outdated PowerShell Modules
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在最简单的情况下，您可以仅使用单行代码（删除 `-WhatIf` 以实际执行更新）检查所有已安装的模块以进行更新：

```powershell
PS C:\> Get-InstalledModule | Update-Module -WhatIf
```

`Get-InstalledModule` 列出了以“托管”方式安装的所有模块（使用 `Install-Module`），并包含有关该模块的安装位置的信息（即 PowerShell Gallery 网站）。这就是 `Update-Module` 用来检查新版本所需要的信息。

如果您只是想看看是否有模块需要更新，并且仅专注于 PowerShell Gallery 安装的模块，那么以下是检查更新的一种更快的方法：

```powershell
function Test-GalleryModuleUpdate
{
    param
    (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]
        $Name,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [version]
        $Version,

        [switch]
        $NeedUpdateOnly

    )

    process
    {
        $URL = "https://www.powershellgallery.com/packages/$Name"
        $page = Invoke-WebRequest -Uri $URL -UseBasicParsing -Maximum 0 -ea Ignore
        [version]$latest  = Split-Path -Path $page.Headers.Location -Leaf
        $needsupdate = $Latest -gt $Version

        if ($needsupdate -or (!$NeedUpdateOnly.IsPresent))
        {
            [PSCustomObject]@{
                ModuleName = $Name
                CurrentVersion = $Version
                LatestVersion = $Latest
                NeedsUpdate = $needsupdate
            }
        }
    }
}

Get-InstalledModule | Where-Object Repository -eq PSGallery |
    Test-GalleryModuleUpdate #-NeedUpdateOnly
```

`Test-GalleryModuleUpdate` 函数读取了 `Get-InstalledModule` 返回的模块，并检查在 powershellgallery.com 上是否发布了新版本。此检查是由通过解析 URL 快速完成的。如果添加 `-NeedUpdateOnly` switch 参数，则 `Test-GalleryModuleUpdate` 仅返回需要更新的模块（可能没有结果）。

这是示例输出：

    ModuleName    CurrentVersion LatestVersion NeedsUpdate
    ----------    -------------- ------------- -----------
    ImportExcel   7.5.2          7.5.3                True
    PSEventViewer 1.0.17         1.0.22               True
    Az.Tools.P... 0.5.0          1.0.1                True
    Microsoft.... 16.0.21116.... 16.0.22413...        True
    MicrosoftT... 2.3.1          4.4.1                True
    PSReadLine    2.2.2          2.2.5                True
    PSWriteHTML   0.0.172        0.0.174              True
    ...

<!--本文国际来源：[Quickly Finding Outdated PowerShell Modules](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/quickly-finding-outdated-powershell-modules)-->

