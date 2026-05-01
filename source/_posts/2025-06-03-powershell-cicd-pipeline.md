---
layout: post
date: 2025-06-03 08:00:00
title: "PowerShell 技能连载 - CI/CD 流水线集成"
description: PowerTip of the Day - CI/CD Pipeline Integration with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- cicd
- pipeline
- devops
- github-actions
---

_适用于 PowerShell 7.0 及以上版本_

持续集成/持续部署（CI/CD）是现代 DevOps 的核心实践。PowerShell 作为 Windows 生态的首选脚本语言，天然适配 Azure DevOps、GitHub Actions、Jenkins 等 CI/CD 平台。通过编写结构化的部署脚本，可以将应用发布流程标准化、可重复、可审计。

本文将讲解如何编写适配 CI/CD 的 PowerShell 部署脚本、多环境配置管理，以及 GitHub Actions 的集成示例。

## CI/CD 脚本设计原则

好的 CI/CD 脚本应遵循以下原则：幂等性（多次执行结果相同）、参数化（通过参数控制行为）、结构化输出（便于日志解析）和错误处理（失败时明确报告原因）：

```powershell
# 标准 CI/CD 脚本模板
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment,

    [string]$Version,
    [string]$ConfigPath = "./config",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "`n========== $Message ==========" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  OK: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  FAIL: $Message" -ForegroundColor Red
}

# 加载环境配置
Write-Step "加载配置：$Environment"
$configFile = Join-Path $ConfigPath "$Environment.json"
if (-not (Test-Path $configFile)) {
    Write-Fail "配置文件不存在：$configFile"
    exit 1
}
$config = Get-Content $configFile | ConvertFrom-Json
Write-Success "配置已加载"

# 构建步骤
Write-Step "构建应用"
$buildOutput = Join-Path $PWD "dist"
if (Test-Path $buildOutput) { Remove-Item $buildOutput -Recurse -Force }

if (-not $DryRun) {
    # 实际构建逻辑
    dotnet publish -c Release -o $buildOutput
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "构建失败"
        exit 1
    }
}
Write-Success "构建完成"

Write-Host "`n部署就绪：$Environment @ $Version" -ForegroundColor Green
```

执行结果示例：

```
========== 加载配置：production ==========
  OK: 配置已加载

========== 构建应用 ==========
  OK: 构建完成

部署就绪：production @ 2.5.0
```

## 多环境配置管理

```powershell
# 环境配置文件结构
$configs = @{
    dev = @{
        AppName    = "myapp-dev"
        Server     = "dev-server-01"
        Port       = 8080
        Debug      = $true
        LogLevel   = "Debug"
        Database   = "Server=dev-db;Database=myapp_dev;"
    }
    staging = @{
        AppName    = "myapp-staging"
        Server     = "staging-server-01"
        Port       = 80
        Debug      = $false
        LogLevel   = "Information"
        Database   = "Server=staging-db;Database=myapp_staging;"
    }
    production = @{
        AppName    = "myapp"
        Server     = "prod-server-01"
        Port       = 80
        Debug      = $false
        LogLevel   = "Warning"
        Database   = "Server=prod-db;Database=myapp_prod;"
    }
}

# 生成配置文件
foreach ($env in $configs.Keys) {
    $path = "config/$env.json"
    $configs[$env] | ConvertTo-Json -Depth 5 | Set-Content $path
    Write-Host "已生成：$path" -ForegroundColor Green
}

# 安全配置替换（从环境变量读取敏感信息）
function Get-SecureConfig {
    param([string]$Environment)

    $config = Get-Content "config/$Environment.json" | ConvertFrom-Json

    # 从环境变量替换敏感配置
    $config.Database = $config.Database -replace 'Database=',
        "User ID=$($env:DB_USER);Password=$($env:DB_PASSWORD);Database="

    return $config
}
```

执行结果示例：

```
已生成：config/dev.json
已生成：config/staging.json
已生成：config/production.json
```

## GitHub Actions 集成

以下是一个完整的 GitHub Actions 工作流，使用 PowerShell 执行部署：

```powershell
# 生成 GitHub Actions 工作流文件
$workflow = @'
name: Deploy Application

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - dev
          - staging
          - production

jobs:
  deploy:
    runs-on: windows-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}

    steps:
      - uses: actions/checkout@v4

      - name: Run deployment script
        shell: pwsh
        env:
          DB_USER: ${{ secrets.DB_USER }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        run: |
          ./scripts/deploy.ps1 `
            -Environment "${{ github.event.inputs.environment || 'staging' }}" `
            -Version "${{ github.sha }}"

      - name: Health check
        shell: pwsh
        run: |
          $env_name = "${{ github.event.inputs.environment || 'staging' }}"
          $config = Get-Content "config/$env_name.json" | ConvertFrom-Json
          $url = "http://$($config.Server):$($config.Port)/health"

          try {
            $response = Invoke-RestMethod -Uri $url -TimeoutSec 30
            Write-Host "Health check passed: $($response.status)"
          } catch {
            Write-Error "Health check failed: $($_.Exception.Message)"
            exit 1
          }
'@

$workflowDir = ".github/workflows"
New-Item -Path $workflowDir -ItemType Directory -Force | Out-Null
Set-Content -Path "$workflowDir/deploy.yml" -Value $workflow
Write-Host "GitHub Actions 工作流已创建" -ForegroundColor Green
```

执行结果示例：

```
GitHub Actions 工作流已创建
```

## 部署回滚脚本

```powershell
function Invoke-Rollback {
    <#
    .SYNOPSIS
    回滚到指定版本
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Environment,

        [string]$TargetVersion,

        [int]$KeepReleases = 5
    )

    $releaseDir = "C:\Releases\$Environment"
    $currentLink = Join-Path $releaseDir "current"

    # 获取当前版本
    $currentVersion = (Get-Item $currentLink -ErrorAction SilentlyContinue).Target
    Write-Host "当前版本：$currentVersion" -ForegroundColor Cyan

    # 列出可用版本
    $releases = Get-ChildItem $releaseDir -Directory |
        Where-Object { $_.Name -match '^\d{8}-\d{6}-v' } |
        Sort-Object Name -Descending

    Write-Host "可用版本：" -ForegroundColor Yellow
    $releases | Select-Object -First 10 Name |
        Format-Table -AutoSize

    if ($TargetVersion) {
        $target = $releases | Where-Object { $_.Name -like "*$TargetVersion*" }
    } else {
        $target = $releases[1]  # 上一个版本
    }

    if (-not $target) {
        Write-Error "未找到目标版本"
        return
    }

    Write-Host "回滚到：$($target.Name)" -ForegroundColor Yellow

    # 更新符号链接
    if (Test-Path $currentLink) { Remove-Item $currentLink }
    New-Item -ItemType SymbolicLink -Path $currentLink -Target $target.FullName | Out-Null

    # 重启应用
    Restart-Service "MyApp-$Environment"
    Write-Host "回滚完成" -ForegroundColor Green

    # 清理旧版本
    $toDelete = $releases | Select-Object -Skip $KeepReleases
    foreach ($old in $toDelete) {
        Remove-Item $old.FullName -Recurse -Force
        Write-Host "已清理：$($old.Name)" -ForegroundColor DarkGray
    }
}
```

执行结果示例：

```
当前版本：20250603-080000-v2.5.0
可用版本：
Name
----
20250603-080000-v2.5.0
20250602-080000-v2.4.0
20250601-080000-v2.3.0

回滚到：20250602-080000-v2.4.0
回滚完成
```

## 部署通知

```powershell
function Send-DeploymentNotification {
    param(
        [string]$Environment,
        [string]$Version,
        [string]$Status,
        [string]$WebhookUrl
    )

    $color = switch ($Status) {
        'success' { '#36a64f' }
        'failed'  { '#ff0000' }
        'rollback' { '#ff9800' }
        default   { '#808080' }
    }

    $body = @{
        attachments = @(
            @{
                color = $color
                blocks = @(
                    @{
                        type = 'section'
                        text = @{
                            type = 'mrkdwn'
                            text = "*部署${Status}*`n环境：$Environment`n版本：$Version`n操作人：$env:USER`n时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                        }
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType 'application/json'
    Write-Host "通知已发送" -ForegroundColor Green
}

# 成功通知
Send-DeploymentNotification -Environment "production" -Version "2.5.0" -Status "success" -WebhookUrl $env:SLACK_WEBHOOK
```

执行结果示例：

```
通知已发送
```

## 注意事项

1. **幂等性**：部署脚本必须幂等，重复执行不应导致错误或数据不一致
2. **蓝绿部署**：生产环境建议使用蓝绿部署或金丝雀发布策略，降低部署风险
3. **密钥管理**：敏感配置应使用 CI/CD 平台的密钥管理（GitHub Secrets、Azure Key Vault），不要提交到代码仓库
4. **回滚策略**：始终保留最近 N 个版本的发布包，确保可以快速回滚
5. **健康检查**：部署后自动执行健康检查，确认服务正常运行后再标记部署完成
6. **审计日志**：所有部署操作应记录审计日志，包括时间、操作人、版本号和结果
