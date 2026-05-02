---
layout: post
date: 2025-12-25 08:00:00
updated: 2025-12-25 08:00:00
title: "PowerShell 技能连载 - 包管理与依赖控制"
description: PowerTip of the Day - Package Management and Dependency Control in PowerShell
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
---

_适用于 PowerShell 5.1 及以上版本_

PowerShell 模块生态在过去几年里蓬勃发展，PowerShell Gallery 上已经托管了数以万计的模块。从日常运维的 Active Directory 管理，到云端自动化的 Az 模块，再到新兴的 AI 交互工具，几乎每种场景都有对应的模块可用。然而，模块数量的增长也带来了管理上的挑战：不同项目依赖同一个模块的不同版本、私有环境的离线分发需求、以及供应链安全对模块来源的审计要求，都是实际工作中必须面对的问题。

PowerShell 7 引入了 **PSResourceGet**（Microsoft.PowerShell.PSResourceGet）作为新一代包管理引擎，替代了沿用多年的 PowerShellGet v2。PSResourceGet 基于 NuGet 协议重新实现了仓库交互，在性能、安全性和功能覆盖面上都有显著提升。同时，它保留了与 PowerShellGet 类似的命令风格，降低了迁移成本。对于仍然运行在 Windows PowerShell 5.1 环境中的系统，PowerShellGet 依然可用，但强烈建议尽早迁移到 PSResourceGet。

本文将从基础操作入手，逐步介绍模块搜索与安装、版本锁定与依赖分析，以及私有仓库的搭建方法，帮助你在不同规模的自动化环境中实现可靠的包管理与依赖控制。

<!-- more -->

## PSResourceGet 基础操作

PSResourceGet 的核心操作围绕"仓库（Repository）"展开。仓库是模块的存储和分发端点，默认连接到 PowerShell Gallery。下面的代码展示了从注册仓库到搜索、安装、更新模块的完整流程。

```powershell
# 安装 PSResourceGet 模块（如果尚未安装）
Install-Module Microsoft.PowerShell.PSResourceGet -Force -Scope CurrentUser

# 查看已注册的仓库
Get-PSResourceRepository

# 注册额外的仓库，例如自定义的 NuGet 源
Register-PSResourceRepository -Name 'MyCompanyFeed' -Uri 'https://nuget.mycompany.com/v3/index.json'

# 搜索模块：在所有仓库中查找包含 "Az" 关键字的模块
Find-PSResource -Name '*Az*' -Type Module -Repository 'PSGallery' | Select-Object Name, Version, Description | Format-Table -AutoSize

# 安装指定模块的最新稳定版本
Install-PSResource -Name 'Pester' -Scope CurrentUser -TrustRepository

# 安装指定版本的模块
Install-PSResource -Name 'Pester' -Version '5.5.0' -Scope CurrentUser

# 更新已安装的模块到最新版本
Update-PSResource -Name 'Pester' -Scope CurrentUser

# 查看本地已安装的模块信息
Get-InstalledPSResource -Name 'Pester'
```

上述代码中，`Register-PSResourceRepository` 用于注册自定义仓库，`Find-PSResource` 支持通配符搜索并可以限定仓库范围，`Install-PSResource` 和 `Update-PSResource` 分别完成安装与升级操作。`-TrustRepository` 参数表示信任该仓库，避免每次安装时都弹出确认提示。

执行结果示例：

```
Name            Uri                                     Trusted
----            ---                                     -------
PSGallery       https://www.powershellgallery.com/api/… False
MyCompanyFeed   https://nuget.mycompany.com/v3/index…   True

Name                    Version  Description
----                    -------  -----------
Az                      12.0.0   Microsoft Azure PowerShell
Az.Accounts             3.0.0    Microsoft Azure PowerShell - Accounts
Az.Compute              7.0.0    Microsoft Azure PowerShell - Compute

Name   Version Prerelease Repository Description
----   ------- ---------- ---------- -----------
Pester 5.7.1              PSGallery  Pester is the ubiquitous test…
```

## 版本锁定与依赖管理

在自动化管道和多人协作的项目中，模块版本的一致性至关重要。不同开发者或不同环境如果安装了不兼容的模块版本，可能导致脚本行为不一致甚至运行失败。PSResourceGet 提供了多种版本控制机制来应对这一问题。

```powershell
# 安装精确版本（版本锁定）
Install-PSResource -Name 'Az.Accounts' -Version '3.0.0' -Scope CurrentUser

# 安装版本范围内的最新版本（支持 NuGet 版本范围语法）
# [3.0.0, 4.0.0) 表示大于等于 3.0.0 且小于 4.0.0
Install-PSResource -Name 'Az.Accounts' -Version '[3.0.0, 4.0.0)' -Scope CurrentUser

# 安装预发布版本
Install-PSResource -Name 'Pester' -Version '6.0.0' -Prerelease -Scope CurrentUser

# 查看模块的依赖关系
$resource = Find-PSResource -Name 'Az.Compute' -Repository 'PSGallery'
$resource.Dependencies | Format-Table Name, VersionRange -AutoSize

# 导出当前环境的模块清单（用于版本锁定文件）
$installed = Get-InstalledPSResource
$lockData = $installed | ForEach-Object {
    [PSCustomObject]@{
        Name    = $_.Name
        Version = $_.Version
    }
}
$lockData | ConvertTo-Json -Depth 3 | Set-Content -Path './modules.lock.json' -Encoding UTF8

# 根据锁定文件批量恢复模块
$lock = Get-Content -Path './modules.lock.json' -Raw | ConvertFrom-Json
foreach ($entry in $lock) {
    Install-PSResource -Name $entry.Name -Version $entry.Version -Scope CurrentUser -ErrorAction SilentlyContinue
}
```

这段代码展示了几个关键的版本管理技巧：使用 `RequiredVersion` 精确锁定版本，使用 NuGet 版本范围语法控制兼容范围，通过 `Dependencies` 属性分析模块的依赖树，以及将环境状态导出为 JSON 锁定文件以便在另一台机器上复现。

执行结果示例：

```
Name       VersionRange
----       ------------
Az.Accounts  [3.0.0, 4.0.0)

modules.lock.json 内容示例：
[
  {
    "Name": "Pester",
    "Version": "5.7.1"
  },
  {
    "Name": "Az.Accounts",
    "Version": "3.0.0"
  },
  {
    "Name": "Az.Compute",
    "Version": "7.0.0"
  }
]
```

## 私有仓库搭建与内网分发

在企业环境中，出于安全审计或网络隔离的需要，通常不希望服务器直接访问公网的 PowerShell Gallery。搭建私有仓库可以解决这个问题，同时也能用于分发团队内部开发的模块。NuGet.Server 是一种轻量级的私有仓库方案，配合 PSResourceGet 可以实现完整的内网分发流程。

```powershell
# ========== 服务端：搭建 NuGet.Server ==========

# 安装 NuGet.Server 包（在一台有 IIS 的 Windows 服务器上执行）
# 首先确保 NuGet 包源已注册
Register-PackageSource -Name 'NuGetGallery' -Location 'https://www.nuget.org/api/v2' -ProviderName NuGet -Trusted

# 创建 NuGet.Server 站点的目录
$sitePath = 'C:\PSGallery\Private'
New-Item -ItemType Directory -Path $sitePath -Force

# 使用 dotnet 方式创建 NuGet.Server（需要 .NET SDK）
# 或者直接下载 NuGet.Server 包并解压
Save-Package -Name NuGet.Server -Source 'NuGetGallery' -Path $sitePath

# 将自定义模块打包为 nupkg 并发布到私有仓库
$modulePath = 'C:\Modules\MyUtils'
$nupkgOutput = 'C:\PSGallery\Packages'

# 使用 PSResourceGet 发布模块
Publish-PSResource -Path $modulePath -Repository 'MyCompanyFeed' -ApiKey 'your-api-key-here'

# ========== 客户端：从私有仓库安装 ==========

# 在客户端机器上注册私有仓库
Register-PSResourceRepository -Name 'CompanyGallery' -Uri 'https://psgallery.mycompany.com/v3/index.json' -Trusted

# 设置默认仓库优先级（私有仓库优先于公网）
Set-PSResourceRepository -Name 'CompanyGallery' -Priority 1

# 从私有仓库搜索和安装模块
Find-PSResource -Name 'MyUtils' -Repository 'CompanyGallery'
Install-PSResource -Name 'MyUtils' -Repository 'CompanyGallery' -Scope CurrentUser

# 验证模块来源
Get-InstalledPSResource -Name 'MyUtils' | Select-Object Name, Version, Repository
```

上述代码分为服务端和客户端两部分。服务端负责搭建 NuGet.Server 并发布内部模块，客户端则注册私有仓库、设置优先级，并从中安装模块。通过设置 `Priority` 参数，可以确保私有仓库中的模块优先于公网同名模块被使用，这在覆盖公网模块的场景中非常有用。

执行结果示例：

```
Name    Version Repository       Description
----    ------- ----------       -----------
MyUtils 1.2.0   CompanyGallery   Company internal utility module…

Name    Version Repository
----    ------- ----------
MyUtils 1.2.0   CompanyGallery
```

## 注意事项

1. **PSResourceGet 与 PowerShellGet 的兼容性**：PSResourceGet 可以管理由 PowerShellGet v2/v3 安装的模块，但反向操作可能存在兼容性问题。建议在团队内统一使用 PSResourceGet，避免混用导致的版本记录混乱。

2. **版本范围语法**：PSResourceGet 使用 NuGet 版本范围语法，方括号表示包含边界、圆括号表示排除边界。例如 `[1.0.0, 2.0.0)` 表示大于等于 1.0.0 且小于 2.0.0。务必仔细检查范围表达式，避免因语法错误导致意外安装了不兼容的版本。

3. **模块锁定文件应纳入版本控制**：`modules.lock.json` 类似于 npm 的 `package-lock.json`，应与项目代码一起提交到 Git 仓库。这样可以确保 CI/CD 管道中的模块版本与开发环境完全一致。

4. **私有仓库的安全加固**：生产环境的私有仓库应启用 HTTPS、配置 API Key 认证，并定期审计已发布的模块内容。对于高安全要求的环境，可以考虑使用 Azure Artifacts 或 JFrog Artifactory 等企业级制品仓库。

5. **离线环境的模块分发**：对于完全隔离的网络环境，可以使用 `Save-PSResource` 将模块及其依赖下载到本地目录，然后通过 U 盘或内部文件共享拷贝到目标机器，再用 `Install-PSResource` 从本地路径安装。这种方式不需要搭建完整的 NuGet 服务。

6. **模块依赖冲突排查**：当遇到模块加载冲突时，可以使用 `Get-Module -ListAvailable` 查看所有可用版本，结合 `$env:PSModulePath` 分析模块搜索路径的优先级。对于冲突严重的环境，考虑使用 PowerShell 的 Assembly Load Context（ALC）隔离机制，或在不同项目中使用独立的模块安装路径。
