---
layout: post
date: 2025-05-07 08:00:00
updated: 2025-05-07 08:00:00
title: "PowerShell 技能连载 - PowerShell Gallery 与模块管理"
description: PowerTip of the Day - PowerShell Gallery and Module Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- module
- powershell-gallery
- package-management
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 的强大很大程度上归功于其丰富的模块生态。PowerShell Gallery 是微软官方的模块仓库，目前托管了超过 4000 个模块，涵盖 Azure 管理、AWS 集成、安全审计、数据库操作等几乎所有领域。掌握模块的查找、安装、发布和版本管理，是每个 PowerShell 用户提升效率的必经之路。

本文将讲解 PowerShell Gallery 的使用技巧、模块的安装与更新策略、私有仓库搭建，以及如何发布自己的模块。

## 查找与安装模块

PowerShell Gallery 是最大的公共模块仓库，通过 `Find-Module` 和 `Install-Module` 命令即可搜索和安装模块：

```powershell
# 搜索模块（支持通配符）
Find-Module -Name *azure* | Select-Object Name, Version, Description |
    Sort-Object Downloads -Descending | Select-Object -First 10 |
    Format-Table -AutoSize

# 安装模块（首次安装会提示信任仓库）
Install-Module -Name Az.Compute -Scope CurrentUser

# 安装特定版本
Install-Module -Name Pester -RequiredVersion 5.5.0 -Scope CurrentUser

# 安装预发布版本
Install-Module -Name PSScriptAnalyzer -AllowPrerelease -Scope CurrentUser

# 查看已安装的模块
Get-InstalledModule | Select-Object Name, Version, Repository |
    Format-Table -AutoSize
```

执行结果示例：

```
Name                Version  Description
----                -------  -----------
Az                  12.0.0   Microsoft Azure PowerShell
Az.Compute          7.0.0    Microsoft Azure PowerShell - Compute ...
AzureAD             2.0.2.   Azure Active Directory V2 PowerShell...

Name       Version Repository
----       ------- ----------
Az.Compute 7.0.0   PSGallery
Pester     5.5.0   PSGallery
```

> **注意**：首次使用 `Install-Module` 时会提示是否信任 PowerShell Gallery 仓库。可以通过 `-Force` 参数跳过提示，但建议先了解模块内容再安装。

## 模块版本管理

在团队协作中，统一的模块版本非常重要。不同版本的模块可能有不同的命令签名和行为，导致脚本在不同机器上表现不一致。

```powershell
# 查看已安装模块的所有版本
Get-InstalledModule -Name Az | Select-Object Name, Version, InstalledLocation

# 查看模块可用的所有版本
Find-Module -Name Pester -AllVersions |
    Select-Object Version, Description |
    Format-Table -AutoSize

# 更新模块到最新版
Update-Module -Name Pester

# 更新所有已安装模块
Get-InstalledModule | ForEach-Object {
    try {
        Update-Module -Name $_.Name -ErrorAction Stop
        Write-Host "已更新：$($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "更新失败：$($_.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 卸载特定版本
Uninstall-Module -Name Pester -RequiredVersion 4.10.0

# 强制安装指定版本（降级）
Install-Module -Name Pester -RequiredVersion 5.4.0 -Force -Scope CurrentUser
```

执行结果示例：

```
Name  Version InstalledLocation
----  ------- ------------------
Az    11.3.0  C:\Users\admin\Documents\PowerShell\Modules\Az\11.3.0
Az    12.0.0  C:\Users\admin\Documents\PowerShell\Modules\Az\12.0.0

Version  Description
-------  -----------
5.5.0    Pester provides a framework for running BDD style tests...
5.4.1    Pester provides a framework for running BDD style tests...
5.4.0    Pester provides a framework for running BDD style tests...

已更新：Pester
已更新：PSScriptAnalyzer
更新失败：Az - Module 'Az' is already at the latest version
```

## 模块依赖与安装策略

复杂模块通常有大量依赖。例如 `Az` 模块包含了 70+ 个子模块。理解依赖关系有助于解决安装冲突：

```powershell
# 查看模块的依赖关系
Find-Module -Name Az.Automation |
    Select-Object Name, Version,
        @{N='Dependencies'; E={$_.Dependencies | ForEach-Object { "$($_.Name)@$($_.Version)" } | Join-String -Separator ', '}}

# 安装时自动处理依赖
Install-Module -Name Az.Automation -Scope CurrentUser
# 会自动安装 Az.Accounts、Az.Resources 等依赖模块

# 检查已安装模块的依赖链
function Get-ModuleDependencyTree {
    param([string]$ModuleName)

    $module = Get-Module -ListAvailable -Name $ModuleName |
        Sort-Object Version -Descending | Select-Object -First 1

    $result = [System.Collections.Generic.List[PSObject]]::new()

    function ResolveDeps {
        param($Mod, [int]$Depth = 0)
        $result.Add([PSCustomObject]@{
            Module = $Mod.Name
            Version = $Mod.Version.ToString()
            Depth = $Depth
        })
        if ($Mod.RequiredModules) {
            foreach ($dep in $Mod.RequiredModules) {
                ResolveDeps -Mod $dep -Depth ($Depth + 1)
            }
        }
    }

    ResolveDeps -Mod $module
    $result | Format-Table -AutoSize
}

Get-ModuleDependencyTree -ModuleName Pester
```

执行结果示例：

```
Module            Version Depth
------            ------- -----
Pester            5.5.0   0
Microsoft.PowerShell.ScriptAnalyzer 1.22.0 1

Module Version Depth
------ ------- -----
Az.Automation 2.0.0   0
Az.Accounts   4.0.0   1
Az.Resources  6.0.0   1
```

## 保存模块离线安装

在无外网连接的生产环境中，可以先下载模块，再离线部署：

```powershell
# 下载模块到指定目录（不安装）
Save-Module -Name Az.Compute -Path "C:\OfflineModules" -Repository PSGallery

# 下载特定版本
Save-Module -Name Pester -RequiredVersion 5.5.0 -Path "C:\OfflineModules"

# 批量下载常用模块
$modules = @(
    'Az.Accounts', 'Az.Compute', 'Az.Storage', 'Az.Network',
    'Pester', 'PSScriptAnalyzer', 'PSReadLine', 'Terminal-Icons'
)

foreach ($mod in $modules) {
    Write-Host "下载：$mod" -ForegroundColor Cyan
    Save-Module -Name $mod -Path "C:\OfflineModules" -Force
}

# 列出已下载的模块
Get-ChildItem "C:\OfflineModules" -Directory |
    ForEach-Object {
        $mod = Get-ChildItem $_.FullName -Directory | Select-Object -First 1
        [PSCustomObject]@{
            Module  = $_.Name
            Version = $mod.Name
            SizeMB  = [math]::Round((Get-ChildItem $_.FullName -Recurse | Measure-Object Length -Sum).Sum / 1MB, 2)
        }
    } | Format-Table -AutoSize
```

执行结果示例：

```
下载：Az.Accounts
下载：Az.Compute
下载：Pester

Module              Version SizeMB
------              ------- ------
Az.Accounts         4.0.0   12.35
Az.Compute          7.0.0   8.72
Pester              5.5.0   3.45
```

> **注意**：离线安装时，将下载的模块目录复制到目标机器的 `$env:PSModulePath` 中的任一路径下（如 `$HOME\Documents\PowerShell\Modules\`）即可。

## 注册私有仓库

企业环境中通常需要搭建私有模块仓库，用于存放内部工具模块。PowerShell 支持注册多个仓库源：

```powershell
# 注册基于 NuGet 的私有仓库
$repoParams = @{
    Name            = 'InternalPSGallery'
    SourceLocation  = 'https://psgallery.internal.company.com/nuget'
    PublishLocation = 'https://psgallery.internal.company.com/nuget'
    InstallationPolicy = 'Trusted'
}
Register-PSRepository @repoParams

# 查看所有已注册的仓库
Get-PSRepository | Format-Table Name, SourceLocation, Trusted -AutoSize

# 从私有仓库搜索和安装模块
Find-Module -Repository InternalPSGallery |
    Select-Object Name, Version, Description |
    Format-Table -AutoSize

Install-Module -Name Company.Utils -Repository InternalPSGallery

# 也可以使用本地文件共享作为仓库
Register-PSRepository -Name LocalShare `
    -SourceLocation '\\fileserver\PSModules' `
    -PublishLocation '\\fileserver\PSModules' `
    -InstallationPolicy Trusted
```

执行结果示例：

```
Name                 SourceLocation                           Trusted
----                 --------------                           -------
PSGallery            https://www.powershellgallery.com/api/   False
InternalPSGallery    https://psgallery.internal.company.co... True

Name            Version  Description
----            -------  -----------
Company.Utils   1.5.0    内部通用工具函数库
Company.Logging 2.0.1    统一日志模块
```

## 发布自己的模块

开发完模块后，可以发布到 PowerShell Gallery 或私有仓库。发布前需要准备 API Key：

```powershell
# 检查模块清单是否完整
$modulePath = "C:\Projects\MyModule"
Test-ModuleManifest -Path "$modulePath\MyModule.psd1"

# 发布前验证
$publishParams = @{
    Path        = $modulePath
    NuGetApiKey = 'your-api-key-here'
    Repository  = 'PSGallery'
    Verbose     = $true
}

# 先做 Dry Run（不实际上传）
# 可以用 -WhatIf（如果模块支持）
Publish-Module @publishParams

# 发布到私有仓库
Publish-Module -Path $modulePath `
    -Repository InternalPSGallery `
    -NuGetApiKey 'internal-key'
```

执行结果示例：

```
ModuleType Version    Name          ExportedCommands
---------- -------    ----          ----------------
Manifest   1.0.0      MyModule      {Get-MyData, Set-MyConfig, ...}

VERBOSE: Successfully published module 'MyModule' to PSGallery
```

## 模块自动加载优化

PowerShell 3.0 及以上版本支持模块自动加载——首次使用模块中的命令时自动加载对应模块。但在模块数量众多时，这可能影响启动性能：

```powershell
# 查看当前 PSModulePath
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# 禁用自动加载（提高启动速度）
$PSModuleAutoLoadingPreference = 'None'

# 手动导入需要的模块
Import-Module Az.Compute, Pester

# 查看当前已加载的模块
Get-Module | Select-Object Name, Version, ModuleType |
    Format-Table -AutoSize

# 查看模块导出的命令
Get-Command -Module Az.Compute |
    Select-Object Name, CommandType |
    Sort-Object Name |
    Format-Table -AutoSize
```

执行结果示例：

```
C:\Users\admin\Documents\PowerShell\Modules
C:\Program Files\PowerShell\Modules
C:\Windows\system32\WindowsPowerShell\v1.0\Modules

Name           Version ModuleType
----           ------- ----------
Az.Accounts    4.0.0   Script
Az.Compute     7.0.0   Script
Pester         5.5.0   Script

Name                              CommandType
----                              -----------
Get-AzVM                          Function
Get-AzVMSize                      Function
New-AzVM                          Function
Remove-AzVM                       Function
```

## 注意事项

1. **安装范围**：使用 `-Scope CurrentUser` 安装到用户目录，无需管理员权限；`-Scope AllUsers` 安装到系统目录，所有用户可用但需要管理员权限
2. **仓库信任策略**：`InstallationPolicy` 设为 `Trusted` 时跳过安装确认，仅对可信仓库使用
3. **版本锁定**：团队项目建议在 `requirements.psd1` 中锁定模块版本，确保所有成员使用相同版本
4. **预发布版本**：`-AllowPrerelease` 参数用于安装测试版本，生产环境不应使用
5. **模块冲突**：不同模块可能导出同名命令，使用 `Import-Module -Prefix` 添加前缀避免冲突
6. **清理旧版本**：更新模块后旧版本仍保留在磁盘上，定期使用 `Uninstall-Module` 清理不再需要的版本
