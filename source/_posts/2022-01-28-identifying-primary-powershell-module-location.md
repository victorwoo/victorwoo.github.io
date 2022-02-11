---
layout: post
date: 2022-01-28 00:00:00
title: "PowerShell 技能连载 - 识别主 PowerShell 模块位置"
description: PowerTip of the Day - Identifying Primary PowerShell Module Location
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 只是一个脚本引擎。 其所有 cmdlet 来自外部模块，环境变量 `$env:PSModulePath` 返回 PowerShell 自动扫描模块的文件夹：

```powershell
PS> $env:PSModulePath -split ';'
C:\Users\username\Documents\WindowsPowerShell\Modules
C:\Program Files\WindowsPowerShell\Modules
C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules
```

同样，`Get-Module` 查找位于其中一个文件夹中的所有模块和 cmdlet：

```powershell
Get-Module -ListAvailable
```

当您以专家的身份使用 PowerShell 时，确保所有所需的模块（以及其 cmdlet）都可以使用，将越来越重要。因此，第一步是选择一个好的位置来存储新模块，下一步是良好地部署和更新这些模块。

本地存储模块的最佳位置是代表 "AllUsers" 范围的文件夹。在 Windows 系统上，此文件夹位于 Program Files 中，您需要管理员权限来更改它。

在大型企业中部署和更新模块的最佳方法是使用现有的软件部署基础架构和部署模块及其更新，以及之前识别的 "AllUsers" 文件夹。

该文件夹的路径可能会根据您使用的 PowerShell 版本而异。以下是一个脚本，用于计算所有用户的模块位置的路径：

```powershell
# determine the primary module location for your PowerShell version
$path = if ('Management.Automation.Platform' -as [Type])
{
  # PowerShell CLR
  if ([Environment]::OSVersion.Platform -like 'Win*' -or $IsWindows) {
    # on Windows
    Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell'
  }
  else
  {
    # on Non-Windows
    $name = [Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')
    Split-Path -Path $name -Parent
  }
}
else
{
  # Windows PowerShell
  Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
```

在 Windows 上，PowerShell 7 和 Windows PowerShell 可以共享一个文件夹，因此如果您不想专门为 PowerShell 7 部署模块，则可以进一步简化脚本：

```powershell
# determine the primary module location for your PowerShell version
$path = if ([Environment]::OSVersion.Platform -like 'Win*' -or $IsWindows)
{
  # Windows
  Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"
}
else
{
  # Non-Windows
  $name = [Management.Automation.Platform]::SelectProductNameForDirectory('SHARED_MODULES')
  Split-Path -Path $name -Parent
}

$path
```

<!--本文国际来源：[Identifying Primary PowerShell Module Location](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-primary-powershell-module-location)-->

