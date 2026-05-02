---
layout: post
date: 2025-11-14 08:00:00
updated: 2025-11-14 08:00:00
title: "PowerShell 技能连载 - CI/CD 流水线集成"
description: PowerTip of the Day - CI/CD Pipeline Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ci-cd
- pipeline
- devops
- automation
---

_适用于 PowerShell 7.0 及以上版本（跨平台）_

持续集成与持续交付（CI/CD）是现代 DevOps 实践的核心环节。无论是 GitHub Actions、Azure DevOps 还是 GitLab CI，流水线的编排本质上都是将一系列自动化步骤串联起来：代码拉取、依赖安装、测试执行、构建打包、环境部署。PowerShell 作为跨平台的脚本语言，天然适合承担这些步骤的"粘合剂"角色——它既能调用系统命令，又能解析结构化数据，还能与 REST API 交互，是构建 CI/CD 流水线的利器。

很多团队在编写 CI/CD 脚本时仍然依赖 Bash 或 Python，但 PowerShell 在 Windows 和 Linux 上行为一致的特性，加上对 JSON、XML、YAML 的原生支持，使得同一套脚本可以在不同运行器（runner）上无缝切换。尤其是在混合环境中管理 .NET 项目、Azure 资源或 Windows 工作负载时，PowerShell 的优势更加明显。将流水线逻辑封装为 PowerShell 模块后，还能实现跨仓库复用，减少重复维护成本。

本文将通过三个实战场景，展示如何用 PowerShell 构建可测试、可复用、可观测的 CI/CD 自动化脚本：包括流水线阶段编排与结果报告、版本号自动管理、以及部署前置检查。每个示例都尽量贴近真实项目中的使用方式，帮助你快速将 PowerShell 集成到现有流水线中。

<!-- more -->

## 流水线阶段编排与报告

在复杂的 CI/CD 流水线中，我们通常需要将构建过程拆分为多个阶段（如 lint、test、build、deploy），每个阶段可能包含若干步骤。以下脚本展示了如何用 PowerShell 编排这些阶段，并在流水线结束时生成结构化的执行报告。

```powershell
# 定义流水线阶段
$stages = @(
    @{
        Name     = 'Lint'
        Script   = { markdownlint source/_posts/*.md }
        Critical = $false
    },
    @{
        Name     = 'Test'
        Script   = { Invoke-Pester -Path './tests' -Output Minimal }
        Critical = $true
    },
    @{
        Name     = 'Build'
        Script   = { npx hexo generate }
        Critical = $true
    },
    @{
        Name     = 'Deploy'
        Script   = { npx hexo deploy }
        Critical = $true
    }
)

# 执行每个阶段并记录结果
$results = foreach ($stage in $stages) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $errorMessage = ''

    Write-Host "`n========== Stage: $($stage.Name) ==========" -ForegroundColor Cyan

    try {
        $output = & $stage.Script 2>&1
        $success = $LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE
        if (-not $success) {
            $errorMessage = ($output | Select-String -Pattern 'error|fail' -SimpleMatch |
                Select-Object -First 3) -join '; '
        }
    }
    catch {
        $success = $false
        $errorMessage = $_.Exception.Message
    }

    $stopwatch.Stop()

    $statusIcon = if ($success) { 'PASS' } else { 'FAIL' }
    Write-Host "  [$statusIcon] $($stage.Name) ($($stopwatch.Elapsed.ToString('mm\:ss')))" -ForegroundColor $(if ($success) { 'Green' } else { 'Red' })

    [PSCustomObject]@{
        Stage       = $stage.Name
        Status      = if ($success) { 'Passed' } else { 'Failed' }
        Duration    = $stopwatch.Elapsed
        Critical    = $stage.Critical
        Error       = $errorMessage
    }

    # 关键阶段失败则中止流水线
    if (-not $success -and $stage.Critical) {
        Write-Host "`n流水线因关键阶段 [$($stage.Name)] 失败而中止。" -ForegroundColor Red
        break
    }
}

# 输出汇总报告
Write-Host "`n===== Pipeline Summary =====" -ForegroundColor Yellow
foreach ($r in $results) {
    $icon = if ($r.Status -eq 'Passed') { '[PASS]' } else { '[FAIL]' }
    Write-Host ("  {0} {1} ({2})" -f $icon, $r.Stage, $r.Duration.ToString('mm\:ss'))
}
```

执行结果示例：

```
========== Stage: Lint ==========
  [PASS] Lint (00:03)

========== Stage: Test ==========
  [PASS] Test (00:12)

========== Stage: Build ==========
  [FAIL] Build (00:08)

流水线因关键阶段 [Build] 失败而中止。

===== Pipeline Summary =====
  [PASS] Lint (00:03)
  [PASS] Test (00:12)
  [FAIL] Build (00:08)
```

这段脚本的核心设计是 `$stages` 数组，每个阶段用哈希表描述名称、执行脚本块和是否为关键阶段。`Critical` 标记决定该阶段失败后是否中止后续阶段。执行结果收集到 `$results` 中，最终输出汇总报告。这种方式比在 YAML 中堆砌大量 `if-failure` 条件更直观，也便于在本地调试时单独运行某个阶段。

## 自动化版本号管理

语义化版本（Semantic Versioning）是 CI/CD 中版本发布的基石。每次发布前手动修改版本号既容易出错，又难以追溯。以下脚本展示了如何基于 Git 标签自动计算下一个版本号，并更新项目文件。

```powershell
# 获取当前最新 Git 标签
$latestTag = git tag --sort=-v:refname | Select-Object -First 1

if ($latestTag -match '^v(\d+)\.(\d+)\.(\d+)$') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
}
else {
    # 没有有效标签时使用默认版本
    $major, $minor, $patch = 0, 1, 0
}

# 根据本次提交的变更内容决定版本递增策略
$commitMessages = git log "$latestTag..HEAD" --pretty=format:'%s'
$bumpType = 'patch' # 默认递增补丁号

foreach ($msg in $commitMessages) {
    if ($msg -match '^feat!?:') {
        # 包含 feat 提交时递增次版本号
        $bumpType = 'minor'
    }
    if ($msg -match 'BREAKING CHANGE') {
        # 包含破坏性变更时递增主版本号
        $bumpType = 'major'
        break
    }
}

# 计算新版本号
switch ($bumpType) {
    'major' { $major++; $minor = 0; $patch = 0 }
    'minor' { $minor++; $patch = 0 }
    'patch' { $patch++ }
}

$newVersion = "{0}.{1}.{2}" -f $major, $minor, $patch
$prerelease = ''
if ($env:GITHUB_REF -and $env:GITHUB_REF -ne "refs/heads/main") {
    # 非主分支自动添加预发布标识
    $shortSha = git rev-parse --short HEAD
    $prerelease = "-beta.$shortSha"
}

$fullVersion = "v${newVersion}${prerelease}"

Write-Host "上一个版本: $latestTag"
Write-Host "版本递增策略: $bumpType"
Write-Host "新版本号: $fullVersion"

# 输出到 GitHub Actions 环境变量（如果在 CI 中运行）
if ($env:GITHUB_OUTPUT) {
    "version=$fullVersion" | Out-File -Append -Encoding utf8 $env:GITHUB_OUTPUT
    "numeric_version=$newVersion" | Out-File -Append -Encoding utf8 $env:GITHUB_OUTPUT
}
```

执行结果示例：

```
上一个版本: v1.3.2
版本递增策略: minor
新版本号: v1.4.0
```

这段脚本遵循 Conventional Commits 规范来决定版本递增策略：遇到 `feat:` 提交递增次版本号，遇到 `BREAKING CHANGE` 递增主版本号，其余情况递增补丁号。非主分支的构建会自动追加预发布标识。通过 `$env:GITHUB_OUTPUT` 将结果写入 GitHub Actions 的输出变量，后续步骤可以直接引用 `${{ steps.version.outputs.version }}`。

## 部署前置检查脚本

在执行正式部署之前，进行一系列环境就绪检查可以有效防止生产事故。以下脚本演示了如何对目标环境进行健康检查、配置验证和依赖可用性探测。

```powershell
# 部署目标配置
$targetConfig = @{
    AppName       = 'my-webapp'
    HealthUrl     = 'https://my-webapp.example.com/health'
    MinDiskGB     = 10
    RequiredEnv   = @('DATABASE_URL', 'REDIS_URL', 'JWT_SECRET')
    DatabaseHost  = 'db.internal.example.com'
    DatabasePort  = 5432
}

$checks = @(
    @{
        Name = '磁盘空间'
        Test = {
            $drive = Get-PSDrive -Name ($IsLinux ? '/' : 'C')
            $freeGB = [math]::Round($drive.Free / 1GB, 2)
            $freeGB -ge $targetConfig.MinDiskGB
        }
        Detail = {
            $drive = Get-PSDrive -Name ($IsLinux ? '/' : 'C')
            $freeGB = [math]::Round($drive.Free / 1GB, 2)
            "可用 {0:N2} GB（要求 >= {1} GB）" -f $freeGB, $targetConfig.MinDiskGB
        }
    },
    @{
        Name = '环境变量'
        Test = {
            $missing = @()
            foreach ($envName in $targetConfig.RequiredEnv) {
                if (-not [Environment]::GetEnvironmentVariable($envName)) {
                    $missing += $envName
                }
            }
            $missing.Count -eq 0
        }
        Detail = {
            $missing = @()
            foreach ($envName in $targetConfig.RequiredEnv) {
                if (-not [Environment]::GetEnvironmentVariable($envName)) {
                    $missing += $envName
                }
            }
            if ($missing.Count -gt 0) {
                "缺少: " + ($missing -join ', ')
            }
            else {
                '所有必需环境变量已配置'
            }
        }
    },
    @{
        Name = '数据库连通性'
        Test = {
            try {
                $tcp = [System.Net.Sockets.TcpClient]::new()
                $tcp.Connect($targetConfig.DatabaseHost, $targetConfig.DatabasePort)
                $tcp.Close()
                $true
            }
            catch {
                $false
            }
        }
        Detail = {
            "{0}:{1} TCP 连接测试" -f $targetConfig.DatabaseHost, $targetConfig.DatabasePort
        }
    },
    @{
        Name = '应用健康端点'
        Test = {
            try {
                $response = Invoke-WebRequest -Uri $targetConfig.HealthUrl `
                    -TimeoutSec 10 -UseBasicParsing
                $response.StatusCode -eq 200
            }
            catch {
                $false
            }
        }
        Detail = {
            "GET $($targetConfig.HealthUrl)"
        }
    }
)

# 执行所有检查
Write-Host "Deploy Pre-flight Checks for [$($targetConfig.AppName)]`n" -ForegroundColor Cyan

$allPassed = $true
foreach ($check in $checks) {
    $passed = & $check.Test
    $detail = & $check.Detail

    $icon = if ($passed) { '[PASS]' } else { '[FAIL]' }
    $color = if ($passed) { 'Green' } else { 'Red' }
    Write-Host ("  {0} {1} - {2}" -f $icon, $check.Name, $detail) -ForegroundColor $color

    if (-not $passed) {
        $allPassed = $false
    }
}

# 根据检查结果决定是否继续部署
if ($allPassed) {
    Write-Host "`n所有检查通过，可以继续部署。" -ForegroundColor Green
    if ($env:GITHUB_OUTPUT) {
        "deploy_ready=true" | Out-File -Append -Encoding utf8 $env:GITHUB_OUTPUT
    }
}
else {
    Write-Host "`n存在未通过的检查项，请修复后再部署。" -ForegroundColor Red
    if ($env:GITHUB_OUTPUT) {
        "deploy_ready=false" | Out-File -Append -Encoding utf8 $env:GITHUB_OUTPUT
    }
    exit 1
}
```

执行结果示例：

```
Deploy Pre-flight Checks for [my-webapp]

  [PASS] 磁盘空间 - 可用 45.32 GB（要求 >= 10 GB）
  [FAIL] 环境变量 - 缺少: JWT_SECRET
  [PASS] 数据库连通性 - db.internal.example.com:5432 TCP 连接测试
  [PASS] 应用健康端点 - GET https://my-webapp.example.com/health

存在未通过的检查项，请修复后再部署。
```

这个脚本的架构是"配置 + 检查列表"模式。每个检查项包含 `Test`（判断是否通过）和 `Detail`（输出具体信息）两个脚本块。这种声明式的写法使得新增检查项非常简单——只需在 `$checks` 数组中追加一个哈希表即可。检查结果通过 `$env:GITHUB_OUTPUT` 传递给后续流水线步骤，实现"前置检查通过才执行部署"的门控逻辑。

## 注意事项

1. **跨平台兼容性**：PowerShell 7 在 Linux 和 macOS 上的行为与 Windows 基本一致，但部分命令存在差异。例如 `Get-PSDrive` 在 Linux 上只返回文件系统挂载点，Windows 上则包含注册表驱动器。编写跨平台脚本时应充分测试，可利用 `$IsLinux`、`$IsMacOS`、`$IsWindows` 自动变量做条件分支。

2. **错误处理策略**：CI/CD 环境中的脚本应始终使用 `$ErrorActionPreference = 'Stop'`，确保未捕获的异常立即终止脚本，避免"静默失败"导致错误的部署结果。对于预期可能失败的步骤（如网络探测），应使用 `try/catch` 显式捕获异常并记录原因。

3. **敏感信息管理**：流水线脚本中切勿硬编码密码、Token 等敏感信息。应通过 CI/CD 平台的安全变量（GitHub Secrets、Azure DevOps Variable Groups）注入，脚本通过 `$env:SECRET_NAME` 读取。输出日志时注意脱敏，避免 `Write-Host` 打印包含凭据的变量。

4. **幂等性设计**：部署脚本应当是幂等的——重复执行不应产生副作用。例如创建目录前先检查是否已存在，数据库迁移脚本应判断变更是否已应用。这样当流水线因网络超时等原因重试时，不会导致重复部署或数据损坏。

5. **日志与可观测性**：CI/CD 脚本应输出结构化的执行日志，包括时间戳、阶段名称和执行结果。建议在关键节点使用 GitHub Actions 的 `::group::` 和 `::endgroup::` 标记对日志进行分组，方便在流水线界面中折叠和展开。对于长时间运行的步骤，还应输出进度信息以便排查卡顿。

6. **脚本模块化与测试**：将流水线逻辑封装为 `.psm1` 模块后，可以使用 Pester 编写单元测试，确保每次修改不会引入回归。模块化的另一个好处是跨仓库复用——通过 Git Submodule 或 PowerShell Gallery 分发，多个项目可以共享同一套经过验证的部署脚本，减少维护负担。
