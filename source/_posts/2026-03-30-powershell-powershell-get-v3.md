---
layout: post
date: 2026-03-30 08:00:00
updated: 2026-03-30 08:00:00
title: "PowerShell 技能连载 - PowerShellGet v3 与模块生态"
description: PowerTip of the Day - PowerShellGet v3 and Module Ecosystem in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- package-management
- module
- tooling
- best-practices
---

_适用于 PowerShell 7.0 及以上版本_

PowerShell 的强大很大程度上来自于其丰富的模块生态——从 AWS 和 Azure 的云管理工具，到 Pester 测试框架、Plaster 项目脚手架，社区贡献了成千上万的实用模块。而这一切的基石就是包管理器。PowerShellGet v3（即 PSResourceGet）作为新一代包管理模块，基于 NuGet v3 协议从头重写，带来了显著的性能提升和更现代化的 API 设计。

与 v2 相比，PSResourceGet 的安装和搜索速度快了数倍，支持并行下载，资源类型从单一的 Script 和 Module 扩展到了 DSCResource、Command、RoleCapability 等更细粒度的分类。同时，它对私有仓库（如 Azure Artifacts、JFrog Artifactory、Sonatype Nexus）的原生支持，让企业内部模块的分发和管理变得前所未有的便捷。

本文将从三个层面展开：首先介绍 PSResourceGet 的安装配置与基础模块管理操作，然后深入讲解依赖解析与版本锁定策略，最后演示如何将自研模块发布到公共仓库或私有仓库，并融入 CI/CD 流水线。

<!-- more -->

## PSResourceGet 基础：安装、仓库注册与模块搜索

PSResourceGet 是 PowerShell 7 的官方推荐包管理模块。安装后，你需要注册模块仓库（默认自带 PSGallery），然后就可以搜索、安装和更新模块。理解仓库的优先级机制和信任级别设置，是安全使用包管理器的前提。

```powershell
# 安装 PSResourceGet 模块
Install-Module -Name PSResourceGet -Force -Scope CurrentUser
Write-Host "PSResourceGet 安装完成"

# 查看已注册的仓库
Get-PSResourceRepository

# 注册私有 NuGet 仓库（例如 Azure Artifacts）
$repoParams = @{
    Name     = 'MyCompanyGallery'
    Uri      = 'https://pkgs.dev.azure.com/mycompany/_packaging/myFeed/nuget/v3/index.json'
    Trusted  = $true
    Priority = 30
}
Register-PSResourceRepository @repoParams
Write-Host "私有仓库 MyCompanyGallery 注册完成"

# 设置 PSGallery 为受信任（避免每次安装都提示确认）
Set-PSResourceRepository -Name 'PSGallery' -Trusted

# 搜索模块：按关键词查找
Find-PSResource -Name 'Pester' -Repository PSGallery
Write-Host "`n--- 按标签搜索 ---"
Find-PSResource -Tags 'azure' -Repository PSGallery |
    Select-Object -First 5 |
    Format-Table Name, Version, Description -AutoSize

# 搜索特定类型的资源
Find-PSResource -Type Module -Name 'Az.*' |
    Select-Object -First 5 |
    Format-Table Name, Version -AutoSize

# 安装模块
Install-PSResource -Name 'Pester' -Version '[5.0.0,6.0.0)' -Repository PSGallery
Write-Host "`nPester 已安装"

# 查看已安装的模块信息
Get-InstalledPSResource -Name 'Pester' |
    Format-Table Name, Version, InstalledLocation -AutoSize

# 更新模块到最新版
Update-PSResource -Name 'Pester' -Prerelease
Write-Host "Pester 已更新到最新版本（含预发布版）"

# 卸载模块
# Uninstall-PSResource -Name 'SomeOldModule'
```

执行结果示例：

```
PSResourceGet 安装完成

Name       Uri                                      Trusted Priority
----       ---                                      ------- --------
PSGallery  https://www.powershellgallery.com/api/v2 True    50
MyCompanyGallery https://pkgs.dev.azure.com/...      True    30
私有仓库 MyCompanyGallery 注册完成

Name   Version Description
----   ------- -----------
Pester 5.7.1   Pester provides a framework for running BDD tests

--- 按标签搜索 ---
Name          Version Description
----          ------- -----------
Az.Accounts   3.0.2   Microsoft Azure PowerShell...
Az.Compute    7.0.1   Microsoft Azure PowerShell Compute...

Pester 已安装

Name   Version InstalledLocation
----   ------- -----------------
Pester 5.7.1  /Users/user/.local/share/powershell/Modules

Pester 已更新到最新版本（含预发布版）
```

## 模块依赖与版本管理

随着项目规模增长，模块之间的依赖关系会变得复杂。PSResourceGet 支持精确的版本范围语法，可以锁定依赖版本以避免意外升级导致的不兼容问题。掌握版本范围表达式和依赖解析策略，对于维护可重现的自动化环境至关重要。

```powershell
# 版本范围语法速查
$versionExamples = @(
    @{ Expression = '1.2.3';           Meaning = '精确匹配 1.2.3' }
    @{ Expression = '[1.2.3,2.0.0)';   Meaning = '大于等于 1.2.3，小于 2.0.0' }
    @{ Expression = '[1.0.0,)';         Meaning = '大于等于 1.0.0（无上限）' }
    @{ Expression = '(1.0.0,2.0.0)';   Meaning = '大于 1.0.0，小于 2.0.0（不含边界）' }
    @{ Expression = '[1.0.0,2.0.0]';   Meaning = '大于等于 1.0.0，小于等于 2.0.0' }
)
Write-Host "版本范围语法参考:"
$versionExamples | Format-Table -AutoSize

# 使用锁文件管理项目依赖（导出当前环境的模块版本）
$projectModules = @('Pester', 'PSScriptAnalyzer', 'platyPS', 'ModuleBuilder')
$lockData = foreach ($mod in $projectModules) {
    $installed = Get-InstalledPSResource -Name $mod -ErrorAction SilentlyContinue
    if ($installed) {
        [PSCustomObject]@{
            ModuleName = $installed.Name
            Version    = $installed.Version.ToString()
            Repository = $installed.Repository
            Installed  = $installed.InstalledDate.ToString('yyyy-MM-dd')
        }
    }
    else {
        [PSCustomObject]@{
            ModuleName = $mod
            Version    = 'NOT INSTALLED'
            Repository = '-'
            Installed  = '-'
        }
    }
}

$lockFile = Join-Path $PWD 'modules.lock.json'
$lockData | ConvertTo-Json | Set-Content -Path $lockFile -Encoding UTF8
Write-Host "`n依赖锁文件已生成: $lockFile"
$lockData | Format-Table -AutoSize

# 根据锁文件批量安装精确版本
function Install-FromLockFile {
    param([string]$Path = 'modules.lock.json')
    $lock = Get-Content -Path $Path -Raw | ConvertFrom-Json
    foreach ($entry in $lock) {
        if ($entry.Version -eq 'NOT INSTALLED') {
            Write-Warning "跳过未指定的模块: $($entry.ModuleName)"
            continue
        }
        Write-Host "安装 $($entry.ModuleName) @$($entry.Version)..."
        Install-PSResource -Name $entry.ModuleName -Version $entry.Version -Quiet -Reinstall
    }
    Write-Host "`n所有依赖安装完成"
}

# 检查模块兼容性：确认模块是否支持当前平台
function Test-ModuleCompatibility {
    param([string]$ModuleName)
    $mod = Find-PSResource -Name $ModuleName -Repository PSGallery -ErrorAction SilentlyContinue
    if (-not $mod) {
        Write-Warning "未找到模块: $ModuleName"
        return
    }
    $info = [PSCustomObject]@{
        ModuleName   = $mod.Name
        LatestVersion = $mod.Version.ToString()
        PowerShell   = if ($mod.RequiredResource -match 'Core') { 'PS7+' } else { 'PS5.1+' }
        HasPrerelease = $mod.IsPrerelease
    }
    # 检查是否已安装
    $installed = Get-InstalledPSResource -Name $ModuleName -ErrorAction SilentlyContinue
    if ($installed) {
        $info | Add-Member -NotePropertyName 'InstalledVersion' -NotePropertyValue $installed.Version.ToString()
    }
    return $info
}

# 批量检查项目依赖的兼容性
foreach ($mod in $projectModules) {
    $result = Test-ModuleCompatibility -ModuleName $mod
    if ($result) { $result }
}
```

执行结果示例：

```
版本范围语法参考:
Expression       Meaning
----------       -------
1.2.3            精确匹配 1.2.3
[1.2.3,2.0.0)   大于等于 1.2.3，小于 2.0.0
[1.0.0,)         大于等于 1.0.0（无上限）
(1.0.0,2.0.0)   大于 1.0.0，小于 2.0.0（不含边界）
[1.0.0,2.0.0]   大于等于 1.0.0，小于等于 2.0.0

依赖锁文件已生成: /Users/user/project/modules.lock.json

ModuleName       Version  Repository Installed
----------       -------  ---------- ---------
Pester           5.7.1    PSGallery  2026-03-15
PSScriptAnalyzer 1.23.0   PSGallery  2026-03-15
platyPS          0.14.2   PSGallery  2026-03-10
ModuleBuilder    3.0.0    PSGallery  2026-03-01

安装 Pester @5.7.1...
安装 PSScriptAnalyzer @1.23.0...
安装 platyPS @0.14.2...
安装 ModuleBuilder @3.0.0...
所有依赖安装完成

ModuleName       LatestVersion PowerShell HasPrerelease InstalledVersion
----------       ------------- ---------- ------------- ----------------
Pester           5.7.1         PS5.1+     False         5.7.1
PSScriptAnalyzer 1.23.0        PS5.1+     False         1.23.0
platyPS          0.14.2        PS5.1+     False         0.14.2
ModuleBuilder    3.0.0         PS7+       False         3.0.0
```

## 模块发布与 CI/CD 集成

当你开发了自己的 PowerShell 模块并希望在团队或社区中共享时，就需要将它发布到模块仓库。PSResourceGet 提供了 `Publish-PSResource` 命令来简化发布流程。结合 CI/CD 流水线，可以实现代码提交后自动测试、打包和发布的完整工作流。

```powershell
# 准备模块清单（module manifest）
$manifestParams = @{
    Path              = './MyToolModule/MyToolModule.psd1'
    RootModule        = 'MyToolModule.psm1'
    ModuleVersion     = '1.0.0'
    Author            = 'Vic Hamp'
    Description       = '企业内部运维工具集模块'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-SystemReport', 'Start-HealthCheck', 'Reset-ServiceState')
    Tags              = @('Ops', 'Monitoring', 'HealthCheck', 'Enterprise')
    ProjectUri        = 'https://github.com/mycompany/MyToolModule'
    LicenseUri        = 'https://github.com/mycompany/MyToolModule/blob/main/LICENSE'
    ReleaseNotes      = '初始发布：系统报告、健康检查、服务状态重置功能'
    RequiredModules   = @(
        @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
    )
}
New-ModuleManifest @manifestParams
Write-Host "模块清单已创建"

# 验证模块清单有效性
$manifest = Test-ModuleManifest -Path './MyToolModule/MyToolModule.psd1' -ErrorAction Stop
Write-Host "模块名: $($manifest.Name)"
Write-Host "版本: $($manifest.Version)"
Write-Host "导出函数: $($manifest.ExportedFunctions.Keys -join ', ')"

# 发布到 PSGallery（需要 API Key）
function Publish-ModuleToGallery {
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,
        [Parameter(Mandatory)]
        [string]$ApiKey
    )
    $publishParams = @{
        Path          = $ModulePath
        Repository    = 'PSGallery'
        ApiKey        = $ApiKey
       Verbose        = $true
    }
    Publish-PSResource @publishParams
    Write-Host "模块已发布到 PSGallery"
}

# 发布到私有仓库
function Publish-ModuleToPrivateRepo {
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,
        [Parameter(Mandatory)]
        [string]$RepositoryName
    )
    # 私有仓库通常使用 NuGet API Key 或 PAT 认证
    Publish-PSResource -Path $ModulePath -Repository $RepositoryName
    Write-Host "模块已发布到私有仓库: $RepositoryName"
}

# CI/CD 集成示例：生成发布用的 GitHub Actions 工作流配置
$githubActions = @{
    name = 'Publish PowerShell Module'
    on   = @{
        push = @{ tags = @('v*') }
    }
    jobs = @{
        publish = @{
            'runs-on' = 'ubuntu-latest'
            steps     = @(
                @{ uses = 'actions/checkout@v4' }
                @{ name = 'Install PowerShell'; uses = 'PowerShell/setup-pwsh@v1' }
                @{
                    name = 'Install PSResourceGet'
                    run  = 'Install-Module -Name PSResourceGet -Force -Scope CurrentUser'
                    shell = 'pwsh'
                }
                @{
                    name = 'Publish Module'
                    run  = @'
$tag = $env:GITHUB_REF -replace ''refs/tags/v'', ''''
Publish-PSResource -Path ./MyToolModule `
    -Repository PSGallery `
    -ApiKey $env:PSGALLERY_API_KEY
'@
                    shell = 'pwsh'
                    env  = @{ PSGALLERY_API_KEY = '${{ secrets.PSGALLERY_API_KEY }}' }
                }
            )
        }
    }
}

$workflowPath = Join-Path $PWD '.github' 'workflows' 'publish-module.yml'
New-Item -ItemType Directory -Path (Split-Path $workflowPath) -Force | Out-Null
# 使用 ConvertTo-Yaml 需要安装相关模块，这里用 JSON 作为示意
$githubActions | ConvertTo-Json -Depth 10 |
    Set-Content -Path $workflowPath -Encoding UTF8
Write-Host "`nGitHub Actions 工作流已生成: $workflowPath"

# 版本号自动递增工具
function Update-ModuleVersion {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Bump = 'Patch'
    )
    $content = Get-Content -Path $ManifestPath -Raw
    if ($content -match 'ModuleVersion\s*=\s*[''"](\d+)\.(\d+)\.(\d+)[''"]') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        switch ($Bump) {
            'Major' { $major++; $minor = 0; $patch = 0 }
            'Minor' { $minor++; $patch = 0 }
            'Patch' { $patch++ }
        }
        $newVersion = "$major.$minor.$patch"
        $content = $content -replace
            "(ModuleVersion\s*=\s*[''"])\d+\.\d+\.\d+(['""])",
            "`$1$newVersion`$2"
        Set-Content -Path $ManifestPath -Value $content -NoNewline
        Write-Host "版本号已更新为: $newVersion ($Bump)"
    }
    else {
        Write-Warning "未在清单文件中找到 ModuleVersion"
    }
}

Update-ModuleVersion -ManifestPath './MyToolModule/MyToolModule.psd1' -Bump Patch
```

执行结果示例：

```
模块清单已创建
模块名: MyToolModule
版本: 1.0.0
导出函数: Get-SystemReport, Start-HealthCheck, Reset-ServiceState

GitHub Actions 工作流已生成: /Users/user/project/.github/workflows/publish-module.yml
版本号已更新为: 1.0.1 (Patch)
```

## 注意事项

1. **PSResourceGet 与 PowerShellGet v2 的共存问题**：PSResourceGet（模块名 `Microsoft.PowerShell.PSResourceGet`）与旧版 PowerShellGet 可以在同一系统上共存，但不应混用两者的命令来管理同一模块，否则可能导致安装状态不一致。建议在团队中统一选择其中一个，并在项目文档中明确说明。

2. **API Key 安全管理**：发布模块到 PSGallery 需要使用 API Key，该密钥应通过环境变量或 CI/CD 平台的 Secrets 机制注入，绝不能硬编码在脚本或配置文件中。PSGallery 的 API Key 可以在账户设置中按权限范围生成，建议遵循最小权限原则。

3. **私有仓库的认证配置**：企业私有仓库（Azure Artifacts、JFrog 等）通常需要 PAT（Personal Access Token）或特定的 NuGet API Key 进行认证。使用 `Register-PSResourceRepository` 注册仓库时，可以通过 `-Credential` 参数预设凭据，也可在发布时通过 `-ApiKey` 参数动态传入。

4. **版本范围语法要严格**：PSResourceGet 使用 NuGet 版本范围语法（方括号和圆括号的组合），与 npm 或 pip 的语义不同。特别是 `[1.0.0,2.0.0)` 这种左闭右开的区间表达，在锁文件和 CI 脚本中务必仔细核对，否则可能出现依赖版本偏离预期的情况。

5. **模块结构规范**：发布到 PSGallery 的模块必须包含有效的模块清单（`.psd1`），并且清单中的 `FunctionsToExport`、`CmdletsToExport` 等字段应显式列出要公开的成员，而非使用通配符 `*`。这不仅能提升模块加载性能，也便于用户通过 `Get-Command -Module` 发现可用命令。

6. **跨平台兼容性声明**：如果你的模块仅在 Windows 上可用（例如调用了 Win32 API 或 Windows 专属的 .NET 类），务必在模块清单的 `Description` 或 `PrivateData` 中明确说明，并在代码中加入平台检测逻辑，避免 Linux/macOS 用户安装后无法使用而困惑。
