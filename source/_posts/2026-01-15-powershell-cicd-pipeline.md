---
layout: post
date: 2026-01-15 08:00:00
updated: 2026-01-15 08:00:00
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
- cicd
- devops
- pipeline
- github-actions
---

_适用于 PowerShell 7.0 及以上版本_

现代 DevOps 实践中，基础设施即代码（IaC）和自动化测试已经成为标准流程，而 CI/CD 流水线正是将这些实践落地的核心工具。无论是代码提交触发的自动测试，还是合并后自动部署到生产环境，流水线都在其中扮演着承上启下的角色。PowerShell 凭借其强大的系统管理能力和丰富的模块生态，成为了各大 CI/CD 平台中编写构建、测试和部署逻辑的理想选择。

主流 CI/CD 平台（如 GitHub Actions、Azure DevOps、Jenkins）都原生支持运行 PowerShell 脚本。这意味着团队可以用同一门语言编写本地运维脚本和流水线逻辑，减少技术栈切换带来的认知负担。同时，Pester 测试框架可以与流水线深度集成，实现代码质量门控——只有当所有测试用例通过时才允许部署继续推进。

本文将从 GitHub Actions 集成、Azure DevOps 流水线配置和通用流水线工具三个角度，展示如何用 PowerShell 构建健壮的 CI/CD 流水线。

<!-- more -->

## GitHub Actions 中的 PowerShell

GitHub Actions 是目前最流行的 CI/CD 平台之一，它在 Windows、Linux 和 macOS runner 上都原生支持 PowerShell（`pwsh`）。以下代码展示了如何编写一个完整的 GitHub Actions workflow，包含 Pester 测试、代码质量检查和构建产物发布。

```powershell
# 文件路径: .github/workflows/ci.yml
# 以下为 workflow 配置的 PowerShell 等价描述
# 实际 workflow 文件为 YAML 格式

# === 本地模拟 CI 流水线的 PowerShell 脚本 ===

# 1. 安装测试依赖
Write-Host '=== 步骤 1: 安装依赖 ===' -ForegroundColor Cyan
Install-Module -Name Pester -MinimumVersion 5.5 -Force -Scope CurrentUser
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# 2. 运行 PSScriptAnalyzer 代码质量检查
Write-Host '`n=== 步骤 2: 代码质量分析 ===' -ForegroundColor Cyan
$analysisResults = Invoke-ScriptAnalyzer -Path '.\Scripts' -Severity Warning,Error -Recurse
if ($analysisResults) {
    $analysisResults | Format-Table -Property RuleName, Severity, ScriptName, Line, Message -Wrap
    $errorCount = ($analysisResults | Where-Object Severity -eq 'Error').Count
    if ($errorCount -gt 0) {
        Write-Host "发现 $errorCount 个错误，流水线终止" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host '代码质量检查通过，无警告或错误' -ForegroundColor Green
}

# 3. 运行 Pester 测试
Write-Host '`n=== 步骤 3: 运行 Pester 测试 ===' -ForegroundColor Cyan
$pesterConfig = @{
    Run = @{
        Path = '.\Tests'
        PassThru = $true
    }
    TestResult = @{
        Enabled = $true
        OutputPath = 'TestResults.xml'
        OutputFormat = 'JUnitXml'
    }
    CodeCoverage = @{
        Enabled = $true
        Path = '.\Scripts\*.ps1'
        OutputPath = 'Coverage.xml'
    }
}
$result = Invoke-Pester -Configuration $pesterConfig

# 4. 输出测试摘要
Write-Host "`n测试结果摘要:" -ForegroundColor Yellow
Write-Host "  总计: $($result.TotalCount) 个测试"
Write-Host "  通过: $($result.PassedCount)" -ForegroundColor Green
Write-Host "  失败: $($result.FailedCount)" -ForegroundColor Red
Write-Host "  跳过: $($result.SkippedCount)" -ForegroundColor Gray
Write-Host "  耗时: $($result.Duration.TotalSeconds) 秒"

if ($result.FailedCount -gt 0) {
    Write-Host '`n测试未全部通过，流水线终止' -ForegroundColor Red
    exit 1
}

# 5. 打包构建产物
Write-Host '`n=== 步骤 4: 打包构建产物 ===' -ForegroundColor Cyan
$artifactName = "ops-scripts-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$artifactPath = "dist\$artifactName"
New-Item -Path $artifactPath -ItemType Directory -Force | Out-Null
Copy-Item -Path '.\Scripts\*' -Destination $artifactPath -Recurse
Copy-Item -Path '.\Modules' -Destination $artifactPath -Recurse
Copy-Item -Path '.\Config\env.template.ps1' -Destination $artifactPath
Compress-Archive -Path $artifactPath -DestinationPath "dist\$artifactName.zip"
Write-Host "构建产物已打包: dist\$artifactName.zip" -ForegroundColor Green
```

执行结果示例：

```
=== 步骤 1: 安装依赖 ===
正在安装 Pester 5.5.x...
正在安装 PSScriptAnalyzer...

=== 步骤 2: 代码质量分析 ===
代码质量检查通过，无警告或错误

=== 步骤 3: 运行 Pester 测试 ===
[+] D:\OpsScripts\Tests\Get-DiskHealth.Tests.ps1  120ms (3 tests)
[+] D:\OpsScripts\Tests\Deploy-App.Tests.ps1      85ms  (5 tests)
[+] D:\OpsScripts\Tests\Export-Report.Tests.ps1   42ms  (2 tests)

测试结果摘要:
  总计: 10 个测试
  通过: 10
  失败: 0
  跳过: 0
  耗时: 0.35 秒

=== 步骤 4: 打包构建产物 ===
构建产物已打包: dist\ops-scripts-20260115-083000.zip
```

## Azure DevOps 流水线

Azure DevOps 提供了经典的构建/发布管道和 YAML 管道两种模式，两者都深度集成 PowerShell 执行环境。以下代码展示了如何在 Azure DevOps 中实现多阶段流水线，包括构建验证、 staging 环境部署、审批门控和生产环境发布。

```powershell
# Azure DevOps Pipeline Agent 中运行的部署脚本
# 文件路径: scripts/Deploy-Application.ps1

param(
    [Parameter(Mandatory)]
    [ValidateSet('Build', 'Staging', 'Production')]
    [string]$Environment,

    [string]$ArtifactPath,

    [string]$TargetServer
)

# 1. 根据环境加载对应配置
$envConfig = @{
    Build = @{
        Servers   = @('localhost')
        Validate  = $false
        Backup    = $false
        Notify    = $false
    }
    Staging = @{
        Servers   = @('staging-web-01', 'staging-web-02')
        Validate  = $true
        Backup    = $true
        Notify    = $false
    }
    Production = @{
        Servers   = @('prod-web-01', 'prod-web-02', 'prod-web-03')
        Validate  = $true
        Backup    = $true
        Notify    = $true
    }
}
$config = $envConfig[$Environment]

Write-Host "部署环境: $Environment"
Write-Host "目标服务器: $($config.Servers -join ', ')"

# 2. 部署前健康检查
if ($config.Validate) {
    Write-Host '`n执行部署前健康检查...' -ForegroundColor Cyan
    foreach ($server in $config.Servers) {
        $session = New-PSSession -ComputerName $server -ErrorAction Stop
        $result = Invoke-Command -Session $session -ScriptBlock {
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
            $cpu = (Get-CimInstance Win32_Processor | Measure-Object LoadPercentage -Average).Average
            [PSCustomObject]@{
                Server       = $env:COMPUTERNAME
                FreeDiskGB   = [math]::Round($disk.FreeSpace / 1GB, 1)
                CpuUsage     = if ($cpu) { $cpu } else { 0 }
                ServicesUp   = (Get-Service -Name 'W3SVC','WinRM' |
                    Where-Object Status -eq 'Running').Count
            }
        }
        $result | Format-Table -AutoSize
        if ($result.FreeDiskGB -lt 5) {
            throw "服务器 $($result.Server) 磁盘空间不足 ($($result.FreeDiskGB) GB)"
        }
        Remove-PSSession $session
    }
    Write-Host '健康检查通过' -ForegroundColor Green
}

# 3. 备份当前版本
if ($config.Backup) {
    Write-Host "`n备份当前版本..." -ForegroundColor Cyan
    $backupTag = "pre-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    foreach ($server in $config.Servers) {
        Invoke-Command -ComputerName $server -ScriptBlock {
            param($tag)
            $appPath = 'D:\WebApp'
            $backupPath = "D:\Backups\$tag"
            Copy-Item -Path $appPath -Destination $backupPath -Recurse -Force
            Write-Host "  $env:COMPUTERNAME: 已备份至 $backupPath"
        } -ArgumentList $backupTag
    }
    Write-Host '备份完成' -ForegroundColor Green
}

# 4. 执行部署
Write-Host "`n开始部署..." -ForegroundColor Cyan
foreach ($server in $config.Servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        param($src)
        $appPath = 'D:\WebApp'
        # 停止应用
        Stop-WebSite -Name 'Default Web Site' -ErrorAction SilentlyContinue
        # 复制文件
        Copy-Item -Path "$src\*" -Destination $appPath -Recurse -Force
        # 启动应用
        Start-WebSite -Name 'Default Web Site'
        Write-Host "  $env:COMPUTERNAME: 部署完成，站点已启动"
    } -ArgumentList $ArtifactPath
}

# 5. 部署后验证与通知
if ($config.Notify) {
    Write-Host "`n发送部署通知..." -ForegroundColor Cyan
    $notifyBody = @{
        text = "[部署完成] $Environment 环境已于 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成部署"
    } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri $env:WEBHOOK_URL -Method Post `
        -Body $notifyBody -ContentType 'application/json'
    Write-Host '通知已发送' -ForegroundColor Green
}

Write-Host "`n部署流程全部完成" -ForegroundColor Green
```

执行结果示例：

```
部署环境: Staging
目标服务器: staging-web-01, staging-web-02

执行部署前健康检查...
Server          FreeDiskGB  CpuUsage  ServicesUp
------          ----------  --------  -----------
STAGING-WEB-01  45.2        12        2
STAGING-WEB-02  38.7         8        2
健康检查通过

备份当前版本...
  STAGING-WEB-01: 已备份至 D:\Backups\pre-deploy-20260115-090000
  STAGING-WEB-02: 已备份至 D:\Backups\pre-deploy-20260115-090000
备份完成

开始部署...
  STAGING-WEB-01: 部署完成，站点已启动
  STAGING-WEB-02: 部署完成，站点已启动

部署流程全部完成
```

## 通用流水线工具

无论使用哪个 CI/CD 平台，一些通用的流水线工具都是不可或缺的。以下代码封装了代码质量检查、语义版本计算和变更日志自动生成三个常用功能，可以作为独立脚本被任何流水线调用。

```powershell
# 文件路径: scripts/Pipeline-Utils.ps1
# 通用流水线工具函数集

# --- 函数 1: 代码质量门控检查 ---
function Invoke-CodeQualityGate {
    [CmdletBinding()]
    param(
        [string]$Path = '.\Scripts',
        [int]$MaxWarnings = 10,
        [int]$MaxErrors = 0
    )
    $results = Invoke-ScriptAnalyzer -Path $Path -Recurse -Severity Information,Warning,Error
    $summary = $results | Group-Object Severity | ForEach-Object {
        @{ Severity = $_.Name; Count = $_.Count }
    }
    $errorCount = ($results | Where-Object Severity -eq 'Error').Count
    $warningCount = ($results | Where-Object Severity -eq 'Warning').Count

    Write-Host "代码质量报告:" -ForegroundColor Yellow
    Write-Host "  错误: $errorCount (阈值: $MaxErrors)"
    Write-Host "  警告: $warningCount (阈值: $MaxWarnings)"

    $passed = ($errorCount -le $MaxErrors) -and ($warningCount -le $MaxWarnings)
    if ($passed) {
        Write-Host '  结果: 通过' -ForegroundColor Green
    } else {
        Write-Host '  结果: 未通过' -ForegroundColor Red
    }
    return $passed
}

# --- 函数 2: 语义版本计算 ---
function Get-NextSemanticVersion {
    [CmdletBinding()]
    param(
        [string]$TagPrefix = 'v',
        [string]$DefaultVersion = '0.1.0'
    )
    $latestTag = git describe --tags --abbrev=0 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "未找到已有标签，使用默认版本: $DefaultVersion"
        return [version]$DefaultVersion
    }
    $versionStr = $latestTag -replace "^$([regex]::Escape($TagPrefix))"
    $current = [version]$versionStr
    $messages = git log "$latestTag..HEAD" --pretty=format:'%s' 2>$null
    if (-not $messages) {
        Write-Host '没有新的提交，版本不变'
        return $current
    }
    $bump = 'Patch'
    if ($messages -match '^feat(\(|:)') { $bump = 'Minor' }
    if ($messages -match 'BREAKING CHANGE') { $bump = 'Major' }
    $next = switch ($bump) {
        'Major' { [version]::new($current.Major + 1, 0, 0) }
        'Minor' { [version]::new($current.Major, $current.Minor + 1, 0) }
        'Patch' { [version]::new($current.Major, $current.Minor, $current.Build + 1) }
    }
    Write-Host "版本: $current -> $next (递增: $bump)"
    return $next
}

# --- 函数 3: 变更日志自动生成 ---
function New-ChangeLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [version]$Version,
        [string]$TagPrefix = 'v'
    )
    $latestTag = git describe --tags --abbrev=0 2>$null
    $range = if ($LASTEXITCODE -eq 0) { "$latestTag..HEAD" } else { 'HEAD' }
    $messages = git log $range --pretty=format:'%s' 2>$null
    if (-not $messages) {
        Write-Host '没有新变更，跳过 CHANGELOG 生成'
        return
    }

    $lines = @(
        "## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')"
    )

    $features = $messages | Where-Object { $_ -match '^feat' }
    $fixes    = $messages | Where-Object { $_ -match '^fix' }
    $others   = $messages | Where-Object {
        $_ -notmatch '^feat' -and $_ -notmatch '^fix' -and $_ -notmatch '^chore'
    }

    if ($features) {
        $lines += '', '### 新功能'
        $features | ForEach-Object { $lines += "- $_" }
    }
    if ($fixes) {
        $lines += '', '### 修复'
        $fixes | ForEach-Object { $lines += "- $_" }
    }
    if ($others) {
        $lines += '', '### 其他变更'
        $others | ForEach-Object { $lines += "- $_" }
    }

    $changeLogPath = 'CHANGELOG.md'
    $existing = if (Test-Path $changeLogPath) { Get-Content $changeLogPath -Raw } else { '' }
    $newContent = ($lines -join "`n") + "`n`n" + $existing
    Set-Content -Path $changeLogPath -Value $newContent.TrimEnd() -Encoding UTF8
    Write-Host "CHANGELOG 已更新: $changeLogPath" -ForegroundColor Green
}

# --- 主流程: 调用示例 ---
Write-Host '========== 流水线工具执行 ==========' -ForegroundColor Cyan

# 运行代码质量检查
$qualityOk = Invoke-CodeQualityGate -Path '.\Scripts' -MaxWarnings 10 -MaxErrors 0

# 计算下一个版本号
$nextVersion = Get-NextSemanticVersion -TagPrefix 'v'
Write-Host "下一个发布版本: $nextVersion"

# 生成变更日志
New-ChangeLog -Version $nextVersion -TagPrefix 'v'

if ($qualityOk) {
    Write-Host "`n所有门控检查通过，可以继续发布流程" -ForegroundColor Green
} else {
    Write-Host "`n门控检查未通过，请修复后重试" -ForegroundColor Red
    exit 1
}
```

执行结果示例：

```
========== 流水线工具执行 ==========

代码质量报告:
  错误: 0 (阈值: 0)
  警告: 3 (阈值: 10)
  结果: 通过

版本: 1.0.0 -> 1.1.0 (递增: Minor)
下一个发布版本: 1.1.0

CHANGELOG 已更新: CHANGELOG.md

所有门控检查通过，可以继续发布流程
```

## 注意事项

1. **流水线中的执行策略**：CI/CD runner 上的 PowerShell 执行策略可能限制脚本运行。在 workflow 中显式设置 `pwsh -ExecutionPolicy Bypass -File script.ps1`，或在脚本开头使用 `Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned` 来确保脚本能正常执行。

2. **敏感信息管理**：绝不要将 API 密钥、连接字符串等敏感信息硬编码在脚本中。GitHub Actions 使用 Secrets，Azure DevOps 使用 Variable Groups 配合 Key Vault，Jenkins 使用 Credentials Binding。在流水线中通过环境变量（`$env:API_KEY`）引用这些安全值。

3. **Pester 测试的隔离性**：每个测试用例应该独立运行，不依赖其他测试的执行顺序或状态。使用 `BeforeAll` 和 `AfterAll` 进行测试环境的初始化和清理，避免测试之间产生副作用，尤其是在流水线中并发执行测试的场景。

4. **幂等部署设计**：部署脚本必须是幂等的——多次执行的结果与一次执行的结果相同。在部署前先检查目标状态，如果已经是期望状态则跳过操作。这样可以安全地重试失败的部署步骤，而不会产生重复创建或数据损坏等问题。

5. **跨平台兼容性**：如果流水线可能在 Linux 或 macOS runner 上运行，避免使用 Windows 专用的 cmdlet（如 `Stop-WebSite`、`New-PSSession`）。改用 REST API 或 SSH 方式进行远程管理，并使用 `Join-Path` 代替硬编码路径分隔符，确保脚本在不同操作系统上行为一致。

6. **流水线日志与遥测**：在关键步骤添加结构化的日志输出（如 `::group::` 和 `::set-output name=key::value`），便于在流水线界面中快速定位问题。对于长时间运行的部署，建议集成 Slack 或 Teams Webhook 通知，让团队实时感知部署进度和结果。
