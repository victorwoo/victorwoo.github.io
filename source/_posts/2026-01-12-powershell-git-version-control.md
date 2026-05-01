---
layout: post
date: 2026-01-12 08:00:00
title: "PowerShell 技能连载 - 脚本版本控制与 Git"
description: PowerTip of the Day - Script Version Control with Git in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- git
- version-control
- devops
- collaboration
---

_适用于 PowerShell 7.0 及以上版本_

运维脚本是基础设施管理的核心资产，其重要性不亚于应用程序代码。然而现实中，很多团队的脚本文件散落在共享目录或个人电脑中，没有版本历史、没有变更追踪、没有协作机制。当脚本出现问题时，无法快速回滚到上一个稳定版本；当多人同时修改时，很容易互相覆盖、引入冲突。

Git 作为业界标准的分布式版本控制系统，为脚本管理提供了完整的解决方案。结合 PowerShell 生态中的 posh-git 模块，可以在终端中获得丰富的状态提示、Tab 补全和分支可视化，大幅提升日常操作的效率。更重要的是，通过合理的仓库结构和分支策略，可以将脚本的版本管理与 CI/CD 发布流程无缝衔接。

本文将从 Git 基础集成、脚本仓库管理策略和自动化发布流水线三个层面，展示如何用 PowerShell 构建一套完整的脚本版本控制方案。

## Git 基础与 posh-git 集成

posh-git 是专为 PowerShell 设计的 Git 扩展模块，它提供了分支状态提示、命令 Tab 补全和丰富的颜色输出。以下代码演示了 posh-git 的安装配置以及常用的 Git 仓库初始化与分支操作。

```powershell
# 1. 安装 posh-git 模块
Install-Module -Name posh-git -Scope CurrentUser -Force

# 2. 导入模块并添加到 Profile 实现自动加载
Import-Module posh-git
Add-Content -Path $PROFILE -Value 'Import-Module posh-git'

# 3. 初始化脚本仓库
$repoPath = 'D:\OpsScripts'
if (-not (Test-Path $repoPath)) {
    New-Item -Path $repoPath -ItemType Directory | Out-Null
}
Set-Location $repoPath
git init
git config user.name 'OpsTeam'
git config user.email 'ops@example.com'

# 4. 创建初始文件并首次提交
@"
# 运维脚本仓库

本仓库包含生产环境运维脚本。
"@ | Set-Content -Path 'README.md'

git add README.md
git commit -m 'chore: 初始化脚本仓库'

# 5. 分支操作 — 创建功能分支开发新脚本
git checkout -b feature/add-disk-monitor
@"
#Requires -Version 7.0
function Get-DiskHealth {
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    foreach ($computer in $ComputerName) {
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk `
            -Filter 'DriveType=3' -ComputerName $computer
        foreach ($d in $disk) {
            $freePercent = [math]::Round($d.FreeSpace / $d.Size * 100, 1)
            [PSCustomObject]@{
                Computer  = $computer
                Drive     = $d.DeviceID
                FreeGB    = [math]::Round($d.FreeSpace / 1GB, 2)
                TotalGB   = [math]::Round($d.Size / 1GB, 2)
                FreePercent = $freePercent
                Status    = if ($freePercent -lt 10) { 'Critical' }
                            elseif ($freePercent -lt 20) { 'Warning' }
                            else { 'OK' }
            }
        }
    }
}
"@ | Set-Content -Path 'Scripts\Get-DiskHealth.ps1'

git add Scripts\Get-DiskHealth.ps1
git commit -m 'feat: 新增磁盘健康检查函数'

# 6. 合并到主分支
git checkout main
git merge feature/add-disk-monitor --no-ff -m 'merge: 磁盘监控功能分支'

# 7. 查看提交历史（posh-git 增强）
git log --oneline --graph --decorate -10
```

执行结果示例：

```
Installing posh-git...
[main (root-commit) a1b2c3f] chore: 初始化脚本仓库
 1 file changed, 3 insertions(+)
 create mode 100644 README.md
Switched to a new branch 'feature/add-disk-monitor'
[feature/add-disk-monitor d4e5f6a] feat: 新增磁盘健康检查函数
 1 file changed, 28 insertions(+)
 create mode 100644 Scripts/Get-DiskHealth.ps1
Switched to branch 'main'
Merge made by the 'ort' strategy.
 Scripts/Get-DiskHealth.ps1 | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)
 create mode 100644 Scripts/Get-DiskHealth.ps1

*   b7c8d9e (HEAD -> main) merge: 磁盘监控功能分支
|\
| * d4e5f6a (feature/add-disk-monitor) feat: 新增磁盘健康检查函数
|/
* a1b2c3f chore: 初始化脚本仓库
```

## 脚本仓库管理策略

一个结构良好的脚本仓库是版本控制的基础。合理的目录划分、完善的 .gitignore 配置以及统一的模块版本标注，能让团队协作更加高效。以下代码展示了一套适用于运维团队的仓库管理最佳实践。

```powershell
# 1. 创建标准化的仓库目录结构
$folders = @(
    'Scripts\Monitoring'
    'Scripts\Deployment'
    'Scripts\Maintenance'
    'Modules\OpsToolkit'
    'Modules\OpsToolkit\Public'
    'Modules\OpsToolkit\Private'
    'Modules\OpsToolkit\en-US'
    'Config'
    'Tests'
    'Docs'
)
foreach ($folder in $folders) {
    $fullPath = Join-Path -Path $repoPath -ChildPath $folder
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory | Out-Null
    }
}

# 2. 创建 .gitignore 排除敏感信息与临时文件
@"
# 输出文件
*.log
*.csv
*.tmp

# 敏感配置（使用模板文件代替）
Config\local.env
Config\credentials.json

# IDE 和编辑器
.vscode/
.idea/
*.swp

# PowerShell 模块缓存
Modules/*/bin/
Modules/*/obj/

# 测试覆盖率报告
coverage/
"@ | Set-Content -Path '.gitignore'

# 3. 创建配置模板（不含真实凭据）
@"
# 环境配置模板
# 复制为 local.env 后填入真实值
$env:API_ENDPOINT = 'https://api.example.com'
$env:LOG_PATH = 'C:\Logs\OpsToolkit'
"@ | Set-Content -Path 'Config\env.template.ps1'

# 4. 为模块添加语义版本标注
$moduleManifest = @{
    Path          = 'Modules\OpsToolkit\OpsToolkit.psd1'
    RootModule    = 'OpsToolkit.psm1'
    ModuleVersion = '1.0.0'
    Author        = 'OpsTeam'
    CompanyName   = 'IT Operations'
    Description   = '运维工具集模块'
    FunctionsToExport = @('Get-DiskHealth', 'Start-ServiceHealthCheck')
    VariablesToExport  = @()
    CmdletsToExport    = @()
    AliasesToExport    = @()
    FileList      = @(
        'OpsToolkit.psm1',
        'Public\Get-DiskHealth.ps1',
        'Public\Start-ServiceHealthCheck.ps1'
    )
    PrivateData   = @{
        PSData = @{
            Tags       = @('Operations', 'Monitoring', 'DevOps')
            ProjectUri = 'https://git.example.com/ops/OpsScripts'
            ReleaseNotes = '初始版本：包含磁盘监控和服务健康检查功能'
        }
    }
}
New-ModuleManifest @moduleManifest

# 5. 统一提交
git add .
git commit -m 'chore: 建立仓库目录结构与模块骨架'
```

执行结果示例：

```
  创建目录: D:\OpsScripts\Scripts\Monitoring
  创建目录: D:\OpsScripts\Scripts\Deployment
  创建目录: D:\OpsScripts\Scripts\Maintenance
  创建目录: D:\OpsScripts\Modules\OpsToolkit\Public
  创建目录: D:\OpsScripts\Tests
  创建目录: D:\OpsScripts\Docs

[main e1f2a3b] chore: 建立仓库目录结构与模块骨架
 9 files changed, 58 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 Config/env.template.ps1
 create mode 100644 Modules/OpsToolkit/OpsToolkit.psd1
 create mode 100644 Modules/OpsToolkit/OpsToolkit.psm1
```

## 自动化发布流水线

当脚本库逐渐成熟，就需要一套规范的发布流程。语义版本号（SemVer）搭配 Git tag 可以精确定位每一次发布。结合 PowerShell 的字符串处理能力，可以自动从提交记录中提取变更并生成 CHANGELOG，实现从开发到发布的全链路追踪。

```powershell
# 1. 定义语义版本号读取与递增函数
function Step-SemanticVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [version]$CurrentVersion,
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$BumpType = 'Patch'
    )
    switch ($BumpType) {
        'Major' { [version]::new($CurrentVersion.Major + 1, 0, 0) }
        'Minor' { [version]::new($CurrentVersion.Major, $CurrentVersion.Minor + 1, 0) }
        'Patch' { [version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build + 1) }
    }
}

# 2. 从模块清单读取当前版本
$manifestPath = Join-Path $repoPath 'Modules\OpsToolkit\OpsToolkit.psd1'
$manifestData = Test-ModuleManifest -Path $manifestPath -ErrorAction SilentlyContinue
$currentVersion = $manifestData.Version
Write-Host "当前版本: $currentVersion"

# 3. 根据最近提交判断版本号递增类型
$lastTag = git describe --tags --abbrev=0 2>$null
if ($LASTEXITCODE -ne 0) {
    $lastTag = 'v0.0.0'
    $commitsSinceTag = git rev-list HEAD --count
} else {
    $commitsSinceTag = git rev-list "$lastTag..HEAD" --count
}

$recentMessages = git log "$lastTag..HEAD" --pretty=format:'%s' 2>$null
$bumpType = 'Patch'
if ($recentMessages -match '^feat') { $bumpType = 'Minor' }
if ($recentMessages -match '^breaking' -or $recentMessages -match 'BREAKING') {
    $bumpType = 'Major'
}
$newVersion = Step-SemanticVersion -CurrentVersion $currentVersion -BumpType $bumpType
Write-Host "新版本: $newVersion (递增类型: $bumpType)"

# 4. 更新模块清单中的版本号
$manifestContent = Get-Content $manifestPath -Raw
$manifestContent = $manifestContent -replace
    "ModuleVersion\s*=\s*'[^']*'",
    "ModuleVersion = '$newVersion'"
Set-Content -Path $manifestPath -Value $manifestContent -NoNewline

# 5. 自动生成 CHANGELOG
$changeLog = @("# 更新日志`n")
$changeLog += "## [$newVersion] - $(Get-Date -Format 'yyyy-MM-dd')`n"

$featCommits = $recentMessages | Where-Object { $_ -match '^feat' }
$fixCommits  = $recentMessages | Where-Object { $_ -match '^fix' }
$otherCommits = $recentMessages | Where-Object {
    $_ -notmatch '^feat' -and $_ -notmatch '^fix' -and $_ -notmatch '^chore'
}

if ($featCommits) {
    $changeLog += "`n### 新功能`n"
    foreach ($c in $featCommits) {
        $changeLog += "- $c`n"
    }
}
if ($fixCommits) {
    $changeLog += "`n### 修复`n"
    foreach ($c in $fixCommits) {
        $changeLog += "- $c`n"
    }
}
if ($otherCommits) {
    $changeLog += "`n### 其他变更`n"
    foreach ($c in $otherCommits) {
        $changeLog += "- $c`n"
    }
}

$changeLogPath = Join-Path $repoPath 'CHANGELOG.md'
$changeLog | Set-Content -Path $changeLogPath -Encoding UTF8

# 6. 创建 Git tag 并提交
git add .
git commit -m "release: v$newVersion"
git tag -a "v$newVersion" -m "发布版本 $newVersion"
Write-Host "已创建标签 v$newVersion"
```

执行结果示例：

```
当前版本: 1.0.0
新版本: 1.1.0 (递增类型: Minor)

# 更新日志

## [1.1.0] - 2026-01-12

### 新功能
- feat: 新增磁盘健康检查函数
- feat: 添加服务健康自动巡检

### 修复
- fix: 修复日志路径包含空格时的解析错误

### 其他变更
- docs: 更新部署文档

[main f8g9h0i] release: v1.1.0
 3 files changed, 42 insertions(+), 2 deletions(-)
已创建标签 v1.1.0
```

## 注意事项

1. **凭据隔离**：永远不要将密码、Token 或 API Key 硬编码在脚本中。使用环境变量或配置模板（如 `env.template.ps1`），将真实凭据文件加入 `.gitignore`。如果意外提交了敏感信息，需要使用 `git filter-branch` 或 BFG Repo-Cleaner 清除历史记录，而不仅是删除文件。

2. **提交消息规范**：采用 Conventional Commits 格式（`feat:`、`fix:`、`chore:`、`docs:` 等），便于自动生成 CHANGELOG 和判断语义版本递增类型。团队应统一约定并在 Code Review 中严格执行。

3. **分支策略选择**：小型团队可以采用 GitHub Flow（main + feature 分支），大型团队建议使用 GitFlow（main + develop + feature + release + hotfix 分支）。无论哪种策略，禁止直接向 main 分支提交代码，所有变更必须通过 Pull Request 合并。

4. **posh-git 性能**：在大型仓库中，posh-git 的状态提示可能会略微降低终端响应速度。可以通过 `$GitPromptSettings.EnableFileStatus = $false` 关闭文件状态检测，或设置 `$GitPromptSettings.EnablePromptStatus = $false` 完全禁用提示。

5. **模块版本同步**：当使用 `New-ModuleManifest` 或 `Update-ModuleManifest` 更新版本号时，确保 Git tag 与 `ModuleVersion` 字段保持一致。可以在发布脚本中添加断言检查：如果 `git describe --tags` 的版本号与清单中的不一致，终止发布流程。

6. **跨平台路径处理**：PowerShell 7 支持跨平台运行，但 Git 在 Windows 和 Linux 上的路径分隔符不同。脚本中应始终使用 `Join-Path` 和 `Split-Path` 来构建路径，避免硬编码反斜杠或斜杠。
