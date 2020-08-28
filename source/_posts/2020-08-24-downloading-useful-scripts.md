---
layout: post
date: 2020-08-24 00:00:00
title: "PowerShell 技能连载 - 下载有用的脚本"
description: PowerTip of the Day - Downloading Useful Scripts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell Gallery 不仅提供带有新 PowerShell 命令的公共模块，而且还提供公共脚本。在投入时间之前，您可能希望调查是否有人创建了可以执行所需功能的 PowerShell 代码。

这是一个简单的示例，说明了如何通过 PowerShell Gallery 搜索和下载脚本的工作方式：

```powershell
# create temporary folder
$destination = Join-Path -Path $env:temp -ChildPath Scripts
$exists = Test-Path -Path $destination
if (!$exists) { $null = New-Item -Path $destination -ItemType Directory }

# offer to download scripts
Find-Script -Name Get-* | Select-Object -Property Name, Description |
    Out-GridView -Title 'Select script to download' -PassThru |
    ForEach-Object {
        Save-Script -Path $destination -Name $_.Name -Force
        $scriptPath = Join-Path -Path $destination -ChildPath "$($_.Name).ps1"
        ise $scriptPath
    }
```

当您运行此代码时，`Find-Script` 将查找使用 Get 动词的任何脚本。您当然可以更改此设置并搜索您喜欢的任何内容。接下来，所有与您的搜索匹配的脚本都将显示在网格视图窗口中。现在，您可以选择一个或多个听起来很有趣的东西。

然后，PowerShell 将所选脚本下载到一个临时文件夹，然后在 PowerShell ISE 中打开这些脚本。现在，您可以查看源代码并从中选择有用的内容。

注意：由于 `Out-GridView` 中的 bug，您需要等待所有数据到达后才能选择脚本。如果选择脚本并在 `Out-GridView` 仍在接收数据的同时单击“确定”，则不会传递任何数据，也不会下载脚本。

要解决此问题，请等待足够长的时间以完全填充网格视图窗口，或者通过首先收集所有数据然后仅在网格视图窗口中显示数据来关闭实时模式：

```powershell
# create temporary folder
$destination = Join-Path -Path $env:temp -ChildPath Scripts
$exists = Test-Path -Path $destination
if (!$exists) { $null = New-Item -Path $destination -ItemType Directory }

# offer to download scripts
Write-Warning "Retrieving scripts, hang on..."
# collecting all results in a variable to work around
# Out-GridView bug
$all = Find-Script -Name Get-* | Select-Object -Property Name, Description
$all | Out-GridView -Title 'Select script to download' -PassThru |
    ForEach-Object {
        Save-Script -Path $destination -Name $_.Name -Force
        $scriptPath = Join-Path -Path $destination -ChildPath "$($_.Name).ps1"
        ise $scriptPath
    }
```

<!--本文国际来源：[Downloading Useful Scripts](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/downloading-useful-scripts)-->

