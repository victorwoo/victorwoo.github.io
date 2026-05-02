---
layout: post
date: 2025-10-01 08:00:00
updated: 2025-10-01 08:00:00
title: "PowerShell 技能连载 - PowerShellGet 包管理"
description: PowerTip of the Day - PowerShellGet Package Management
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- package-management
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 背景

在现代运维和开发工作中，模块化管理代码已成为主流趋势。Python 有 pip，Node.js 有 npm，而 PowerShell 的官方包管理工具就是 PowerShellGet。它提供了一组标准 cmdlet，让用户可以从 PowerShell Gallery 或私有 NuGet 源搜索、安装、更新和发布模块及脚本。自 PowerShell 5.0 起，PowerShellGet 已内置于系统中，开箱即用。

在日常工作中，我们经常面临以下场景：团队共享了一批自定义运维模块，需要统一分发和版本控制；某个第三方模块发布了安全补丁，需要快速检查并升级所有服务器上的旧版本；或者我们需要将内部开发的工具模块发布到私有仓库，供多个环境使用。PowerShellGet 正是解决这些问题的利器。

本文将从仓库管理、模块搜索与安装、批量更新、以及私有源搭建等方面，全面介绍 PowerShellGet 的实际用法，帮助你构建高效的 PowerShell 模块管理工作流。

## 查看和管理仓库源

PowerShellGet 依赖 NuGet 协议与仓库交互。默认情况下，系统已注册 PowerShell Gallery 作为公共源。我们可以先查看当前注册的所有仓库，确认源是否可用。

```powershell
# 查看已注册的仓库列表
Get-PSRepository
```

```text
Name                      InstallationPolicy   SourceLocation
----                      -----------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2
```

如果默认的 PSGallery 仓库丢失（某些精简系统可能出现），可以使用以下命令恢复：

```powershell
# 恢复默认的 PSGallery 仓库
Register-PSRepository -Default

# 验证仓库是否恢复成功
Get-PSRepository
```

```text
Name                      InstallationPolicy   SourceLocation
----                      -----------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2
```

在生产环境中，建议将仓库的 InstallationPolicy 设为 Trusted，避免每次安装时都需要手动确认：

```powershell
# 将 PSGallery 设为受信任源
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
```

## 搜索和安装模块

PowerShellGet 提供了 `Find-Module` 和 `Install-Module` 两个核心 cmdlet，分别用于搜索和安装模块。下面演示如何按关键词搜索模块，并查看模块的详细信息。

```powershell
# 按标签搜索安全相关的模块
$modules = Find-Module -Tag 'Security' | Select-Object -First 5

foreach ($m in $modules) {
    Write-Output ("模块名: {0}, 版本: {1}, 描述: {2}" -f $m.Name, $m.Version, $m.Description)
}
```

```text
模块名: Carbon, 版本: 2.5.0, 描述: Carbon is a PowerShell module for automating the configuration of Windows.
模块名: ACMESharp, 版本: 0.8.1, 描述: Client library for the ACME protocol for certificate management.
模块名: DSInternals, 版本: 2.22, 描述: The DSInternals PowerShell Module exposes several internal features of Active Directory.
模块名: DSCEA, 版本: 1.2.0.0, 描述: DSCEA is a scanning engine for processing Test-DscConfiguration results.
模块名: PoshACME, 版本: 3.10.0, 描述: PowerShell module for ACME certificate management.
```

找到需要的模块后，使用 `Install-Module` 进行安装。建议指定 `-Scope CurrentUser` 避免需要管理员权限：

```powershell
# 安装指定模块到当前用户范围
Install-Module -Name 'PSScriptAnalyzer' -Scope CurrentUser -Repository PSGallery

# 确认安装成功
Get-Module -ListAvailable -Name 'PSScriptAnalyzer' | Select-Object Name, Version, ModuleBase
```

```text
Name               Version    ModuleBase
----               -------    ----------
PSScriptAnalyzer   1.22.0     C:\Users\user\Documents\PowerShell\Modules\PSScriptAnalyzer\1.22.0
```

有时候我们需要安装特定版本的模块，比如为了兼容性而回退到旧版本：

```powershell
# 查看模块的所有可用版本
Find-Module -Name 'PSScriptAnalyzer' -AllVersions | Select-Object Name, Version | Sort-Object Version -Descending | Select-Object -First 5
```

```text
Name               Version
----               -------
PSScriptAnalyzer   1.22.0
PSScriptAnalyzer   1.21.0
PSScriptAnalyzer   1.20.0
PSScriptAnalyzer   1.19.1
PSScriptAnalyzer   1.19.0
```

```powershell
# 安装指定版本
Install-Module -Name 'PSScriptAnalyzer' -RequiredVersion '1.21.0' -Scope CurrentUser -Force
```

## 批量检查和更新模块

在维护多台服务器时，定期检查已安装模块是否有更新是一项重要的运维任务。下面的脚本会扫描所有已安装模块，对比 PowerShell Gallery 上的最新版本，并生成更新报告。

```powershell
# 获取所有已安装模块的当前版本和最新版本
$installedModules = Get-InstalledModule
$updateReport = @()

foreach ($mod in $installedModules) {
    $latest = Find-Module -Name $mod.Name -Repository PSGallery -ErrorAction SilentlyContinue

    if ($latest -and $latest.Version -ne $mod.Version) {
        $updateReport += [PSCustomObject]@{
            Name            = $mod.Name
            CurrentVersion  = $mod.Version
            LatestVersion   = $latest.Version
            NeedsUpdate     = $true
        }
    }
    else {
        $updateReport += [PSCustomObject]@{
            Name            = $mod.Name
            CurrentVersion  = $mod.Version
            LatestVersion   = $mod.Version
            NeedsUpdate     = $false
        }
    }
}

$updateReport | Format-Table -AutoSize
```

```text
Name                CurrentVersion  LatestVersion  NeedsUpdate
----                --------------  -------------  -----------
PSScriptAnalyzer    1.21.0          1.22.0             True
PSSqlite            1.1.0           1.1.0             False
PowerShellGet       2.2.5           2.2.5             False
Pester              5.4.0           5.5.0             True
```

确认需要更新的模块后，可以使用 `Update-Module` 进行升级：

```powershell
# 更新所有有新版本的模块
foreach ($mod in $updateReport) {
    if ($mod.NeedsUpdate) {
        Write-Output ("正在更新 {0} 从 {1} 到 {2}..." -f $mod.Name, $mod.CurrentVersion, $mod.LatestVersion)
        Update-Module -Name $mod.Name -Scope CurrentUser
        Write-Output ("{0} 更新完成。" -f $mod.Name)
    }
}
```

```text
正在更新 PSScriptAnalyzer 从 1.21.0 到 1.22.0...
PSScriptAnalyzer 更新完成。
正在更新 Pester 从 5.4.0 到 5.5.0...
Pester 更新完成。
```

## 注册私有 NuGet 仓库

在企业环境中，公共的 PowerShell Gallery 并不总是可用（比如受限网络环境），或者我们需要分发内部开发的专用模块。这时可以注册私有 NuGet 仓库，实现内部模块的统一管理。

```powershell
# 注册企业内部的 NuGet 仓库
$repoParams = @{
    Name               = 'CompanyPSRepo'
    SourceLocation     = 'https://nuget.company.com/v3/index.json'
    PublishLocation    = 'https://nuget.company.com/v3/index.json'
    InstallationPolicy = 'Trusted'
}

Register-PSRepository @repoParams

# 验证注册结果
Get-PSRepository -Name 'CompanyPSRepo'
```

```text
Name                InstallationPolicy   SourceLocation
----                -----------------   --------------
CompanyPSRepo       Trusted              https://nuget.company.com/v3/index.json
```

注册完成后，就可以像使用 PSGallery 一样搜索和安装私有仓库中的模块：

```powershell
# 搜索私有仓库中的模块
Find-Module -Repository 'CompanyPSRepo'

# 从私有仓库安装模块
Install-Module -Name 'Company.Utils' -Repository 'CompanyPSRepo' -Scope CurrentUser
```

```text
Version    Name              Repository      Description
-------    ----              ----------      -----------
1.5.0      Company.Utils     CompanyPSRepo   公司内部通用运维工具模块
2.0.1      Company.Security  CompanyPSRepo   公司安全基线检查模块
1.0.0      Company.Logging   CompanyPSRepo   统一日志记录模块
```

## 发布模块到仓库

开发完一个 PowerShell 模块后，可以使用 `Publish-Module` 将其发布到 PowerShell Gallery 或私有仓库。发布前需要准备好模块清单（.psd1 文件），确保元数据完整。

```powershell
# 查看模块清单信息
$modulePath = 'C:\Modules\MyToolKit'
Test-ModuleManifest -Path "$modulePath\MyToolKit.psd1" | Select-Object Name, Version, Author, Description
```

```text
Name        : MyToolKit
Version     : 1.0.0
Author      : admin
Description : 日常运维工具集
```

```powershell
# 发布模块到私有仓库（使用 API Key 认证）
$publishParams = @{
    Path       = $modulePath
    Repository = 'CompanyPSRepo'
    NuGetApiKey = 'your-api-key-here'
    Verbose    = $true
}

Publish-Module @publishParams
```

```text
VERBOSE: 正在准备要发布的模块 'MyToolKit' (版本 1.0.0)...
VERBOSE: 正在创建 NuGet 包...
VERBOSE: 正在将包推送到 'https://nuget.company.com/v3/index.json'...
VERBOSE: 模块 'MyToolKit' (版本 1.0.0) 发布成功。
```

发布完成后，其他团队成员就可以通过 `Find-Module` 和 `Install-Module` 获取最新版本。

## 注意事项

1. **PowerShellGet 版本差异**：PowerShellGet v2（随 Windows 自带）和 v3（需要单独安装）在 cmdlet 命名和参数上有较大变化。v3 的包名为 `Microsoft.PowerShell.PSResourceGet`，计划在未来替代 v2。迁移前请确认兼容性。

2. **NuGet 提供程序依赖**：首次使用 `Install-Module` 时，系统可能会提示安装 NuGet 提供程序。在企业环境中建议提前部署，可以通过 `Install-PackageProvider -Name NuGet -Force` 预装。

3. **执行策略限制**：如果系统执行策略设置为 `Restricted`，模块安装和脚本执行都会被阻止。建议将执行策略设为 `RemoteSigned`：`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`。

4. **网络代理问题**：在需要通过代理访问外网的环境中，PowerShellGet 默认不会自动使用系统代理。需要显式配置 `PowerShellGet` 的代理设置，或者使用 `-Proxy` 参数指定代理地址。

5. **模块冲突处理**：如果系统中存在多个版本的同一模块，PowerShell 默认加载路径中排在最前面的版本。使用 `Import-Module` 时通过 `-RequiredVersion` 参数明确指定版本，避免意外加载旧版本导致兼容性问题。

6. **私有仓库安全**：发布模块时使用的 API Key 应妥善保管，切勿硬编码在脚本中。建议使用环境变量或 Azure Key Vault 等安全存储来管理凭据，例如 `$apiKey = $env:PSGALLERY_API_KEY`。
