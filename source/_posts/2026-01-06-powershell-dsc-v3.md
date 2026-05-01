---
layout: post
date: 2026-01-06 08:00:00
title: "PowerShell 技能连载 - DSC v3 配置即代码"
description: PowerTip of the Day - DSC v3 Configuration as Code in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- dsc
- configuration-as-code
- infrastructure
- automation
---

_适用于 PowerShell 7.0 及以上版本_

在基础设施即代码（IaC）的实践中，配置管理一直是最核心也最容易出问题的环节。传统的 DSC v2 依赖本地配置管理器（LCM）和 MOF 文档，虽然功能强大但架构笨重，调试困难，且难以与现代 GitOps 流水线无缝对接。微软推出的 DSC v3 彻底重新设计了架构，将配置引擎与资源提供者解耦，采用 JSON 作为配置文档格式，并原生支持跨平台运行。

DSC v3 的设计哲学是"配置即代码"（Configuration as Code）。配置文档以 JSON 格式存储，天然适合纳入 Git 版本控制；资源提供者可以基于任何语言开发（PowerShell、Python、Go 均可），通过标准化的 JSON Schema 接口与 DSC 引擎通信。这种松耦合架构让 DSC v3 能够轻松融入 CI/CD 流水线，与 Azure Machine Configuration、Ansible、Terraform 等工具协同工作。

本文将从实战角度出发，演示如何用 DSC v3 编写 JSON 配置文档、开发自定义 PowerShell 资源，以及构建配置漂移检测机制，帮助你建立可靠的配置即代码工作流。

## DSC v3 配置文档编写

DSC v3 使用 JSON 格式的配置文档来声明系统的期望状态。配置文档包含资源实例的列表，每个实例通过 `type` 指定资源类型，通过 `properties` 定义期望的配置值。下面的代码展示如何编写一份完整的 DSC v3 配置文档，并利用资源发现功能验证配置的合法性。

```powershell
# 定义 DSC v3 配置文档（JSON 格式）
$configDocument = @{
    '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json'
    contentVersion = '1.0.0'
    resources = @(
        @{
            type = 'Microsoft.Windows/Registry'
            name = 'EnableLongPaths'
            properties = @{
                keyPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
                valueName = 'LongPathsEnabled'
                valueData = @{
                    dword = 1
                }
                ensure = 'Present'
            }
        }
        @{
            type = 'Microsoft.Windows/Feature'
            name = 'InstallSSH'
            properties = @{
                name = 'OpenSSH.Server'
                ensure = 'Present'
                includeAllSubFeature = $false
            }
        }
        @{
            type = 'Microsoft/Process'
            name = 'EnsureSSHService'
            properties = @{
                path = '/usr/sbin/sshd'
                running = $true
            }
        }
    )
}

# 将配置保存为 JSON 文件
$configPath = Join-Path $env:TEMP 'dsc-v3-server-config.json'
$configDocument | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8

Write-Host "配置文档已保存至: $configPath"

# 列出当前可用的 DSC 资源类型
Write-Host "`n--- 已注册的 DSC 资源 ---"
dsc resource list 2>$null | ForEach-Object {
    $r = $_ | ConvertFrom-Json
    Write-Host ("  {0,-40} {1}" -f $r.type, $r.version)
}

# 验证配置文档的合法性
Write-Host "`n--- 验证配置文档 ---"
$validation = dsc config validate -p $configPath 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "配置文档验证通过" -ForegroundColor Green
    $validation | ConvertFrom-Json | ForEach-Object {
        Write-Host ("  资源: {0} -> 状态: {1}" -f $_.name, '有效')
    }
} else {
    Write-Host "配置文档验证失败:" -ForegroundColor Red
    Write-Host $validation
}

# 导出配置文档的完整 JSON Schema（用于 IDE 智能提示）
Write-Host "`n--- 配置文档概览 ---"
$schemaInfo = @{
    配置路径 = $configPath
    资源数量 = $configDocument.resources.Count
    资源清单 = $configDocument.resources | ForEach-Object { "$($_.type)[$($_.name)]" }
    版本 = $configDocument.contentVersion
}
$schemaInfo | Format-Table -AutoSize
```

执行结果示例：

```
配置文档已保存至: /tmp/dsc-v3-server-config.json

--- 已注册的 DSC 资源 ---
  Microsoft.Windows/Registry                 0.1.0
  Microsoft.Windows/Feature                  0.2.0
  Microsoft/Process                          0.1.0
  Microsoft/OSInfo                           0.1.0

--- 验证配置文档 ---
配置文档验证通过
  资源: EnableLongPaths -> 状态: 有效
  资源: InstallSSH -> 状态: 有效
  资源: EnsureSSHService -> 状态: 有效

--- 配置文档概览 ---

配置路径                                   资源数量  资源清单                                               版本
--------                                   --------  --------                                               ----
/tmp/dsc-v3-server-config.json             3         {Microsoft.Windows/Registry[EnableLongPaths]...}       1.0.0
```

## 自定义 DSC 资源开发

DSC v3 的资源提供者采用适配器模式，每个资源需要实现 `get`、`set`、`test`、`delete` 四个操作。对于 PowerShell 用户来说，最自然的方式是使用 Class-based 资源。下面的代码演示如何创建一个管理本地用户配置文件的自定义 DSC 资源，包括资源定义、导出和注册。

```powershell
# 定义自定义 DSC 资源的清单文件（manifest）
$resourceManifest = @{
    '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/resource/manifest.json'
    type = 'Contoso.UserProfile'
    version = '1.0.0'
    description = '管理用户环境配置文件'
    get = @{
        executable = 'pwsh'
        args = @(
            '-NoLogo', '-NonInteractive', '-NoProfile', '-Command'
            "Import-Module 'Contoso.DscResources'; Get-TargetResource"
        )
    }
    set = @{
        executable = 'pwsh'
        args = @(
            '-NoLogo', '-NonInteractive', '-NoProfile', '-Command'
            "Import-Module 'Contoso.DscResources'; Set-TargetResource"
        )
        preTest = $true
    }
    test = @{
        executable = 'pwsh'
        args = @(
            '-NoLogo', '-NonInteractive', '-NoProfile', '-Command'
            "Import-Module 'Contoso.DscResources'; Test-TargetResource"
        )
    }
    schema = @{
        embedded = @{
            type = 'object'
            properties = @{
                UserName = @{ type = 'string'; description = '用户名' }
                HomeDirectory = @{ type = 'string'; description = '主目录路径' }
                Shell = @{ type = 'string'; description = '默认 Shell' }
                Ensure = @{
                    type = 'string'
                    enum = @('Present', 'Absent')
                    description = '确保状态'
                }
            }
            required = @('UserName')
        }
    }
}

# 保存资源清单
$manifestPath = Join-Path $env:TEMP 'Contoso.UserProfile.dsc.resource.json'
$resourceManifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8

# 编写 PowerShell 脚本资源实现
$scriptResource = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$UserName,

    [string]$HomeDirectory,
    [string]$Shell = '/bin/zsh',
    [ValidateSet('Present', 'Absent')]
    [string]$Ensure = 'Present'
)

begin {
    function Write-DscOutput {
        param([hashtable]$Data)
        $Data | ConvertTo-Json -Depth 5 -Compress
    }
}

process {
    # 获取当前状态的实际值
    $actualUser = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue
    $actualHome = $actualUser ? (Get-ADUserResultantHomePath $UserName) : $null

    # 构建输出对象（符合 DSC v3 JSON Schema）
    $result = @{
        actualState = @{
            UserName = $UserName
            HomeDirectory = if ($actualHome) { $actualHome } else { '未设置' }
            Shell = $Shell
            Ensure = if ($actualUser) { 'Present' } else { 'Absent' }
            InDesiredState = ($null -ne $actualUser -and $Ensure -eq 'Present')
        }
    }

    Write-DscOutput -Data $result
}
'@

$resourceScript = Join-Path $env:TEMP 'Contoso.DscResources.psm1'
$scriptResource | Set-Content -Path $resourceScript -Encoding UTF8

# 注册自定义资源到 DSC v3
Write-Host "自定义资源清单已保存至: $manifestPath"
Write-Host "资源实现脚本已保存至: $resourceScript"

# 在配置文档中引用自定义资源
$customConfig = @{
    '$schema' = 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2024/04/config/document.json'
    contentVersion = '1.0.0'
    resources = @(
        @{
            type = 'Contoso.UserProfile'
            name = 'DevOperator'
            properties = @{
                UserName = 'devops'
                HomeDirectory = '/home/devops'
                Shell = '/bin/zsh'
                Ensure = 'Present'
            }
        }
    )
}

$customConfigPath = Join-Path $env:TEMP 'dsc-v3-custom-config.json'
$customConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $customConfigPath -Encoding UTF8

Write-Host "`n自定义资源配置文档已保存至: $customConfigPath"
Write-Host "资源类型: Contoso.UserProfile v1.0.0"
Write-Host "包含属性: UserName, HomeDirectory, Shell, Ensure"
```

执行结果示例：

```
自定义资源清单已保存至: /tmp/Contoso.UserProfile.dsc.resource.json
资源实现脚本已保存至: /tmp/Contoso.DscResources.psm1

自定义资源配置文档已保存至: /tmp/dsc-v3-custom-config.json
资源类型: Contoso.UserProfile v1.0.0
包含属性: UserName, HomeDirectory, Shell, Ensure
```

## 配置测试与偏差修正

DSC v3 的核心工作模式是 Get-Test-Set 循环。`get` 操作获取当前实际状态，`test` 操作比较实际状态与期望状态，`set` 操作将系统收敛到期望状态。下面的代码演示如何构建一个完整的配置漂移检测和修正流程，并生成可读的漂移报告。

```powershell
# 定义漂移检测与修正函数
function Invoke-DscDriftDetection {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [switch]$AutoRemediate,

        [switch]$DetailedReport
    )

    $report = [System.Collections.Generic.List[PSObject]]::new()
    $timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'

    # 步骤 1: 获取当前状态（dsc config get）
    Write-Host "[$timestamp] 正在获取当前配置状态..." -ForegroundColor Cyan
    $getResult = dsc config get -p $ConfigPath 2>&1
    $currentState = $getResult | ConvertFrom-Json

    # 步骤 2: 测试配置漂移（dsc config test）
    Write-Host "[$timestamp] 正在检测配置漂移..." -ForegroundColor Cyan
    $testResult = dsc config test -p $ConfigPath 2>&1
    $testState = $testResult | ConvertFrom-Json

    $driftCount = 0
    $inSpecCount = 0

    foreach ($resource in $testState.results) {
        $entry = [ordered]@{
            Timestamp = $timestamp
            ResourceType = $resource.type
            ResourceName = $resource.name
            InDesiredState = $resource.inDesiredState
            DriftDetails = $null
        }

        if (-not $resource.inDesiredState) {
            $driftCount++
            # 提取漂移的具体属性差异
            $diffs = @()
            if ($resource.differences) {
                foreach ($diff in $diff) {
                    $diffs += "{0}: 期望='{1}', 实际='{2}'" -f @(
                        $diff.property
                        $diff.expected
                        $diff.actual
                    )
                }
            } else {
                $diffs = @('状态不匹配')
            }
            $entry.DriftDetails = $diffs -join '; '
            Write-Host ("  [漂移] {0}[{1}]: {2}" -f @(
                $resource.type, $resource.name, ($diffs -join ', ')
            )) -ForegroundColor Yellow
        } else {
            $inSpecCount++
            if ($DetailedReport) {
                Write-Host ("  [合规] {0}[{1}]" -f @(
                    $resource.type, $resource.name
                )) -ForegroundColor Green
            }
        }

        $report.Add([PSCustomObject]$entry)
    }

    # 步骤 3: 输出汇总报告
    Write-Host "`n========== 配置漂移报告 ==========" -ForegroundColor White
    Write-Host ("检测时间: {0}" -f $timestamp)
    Write-Host ("配置文件: {0}" -f $ConfigPath)
    Write-Host ("资源总数: {0}" -f ($driftCount + $inSpecCount))
    Write-Host ("合规数量: {0}" -f $inSpecCount) -ForegroundColor Green
    Write-Host ("漂移数量: {0}" -f $driftCount) -ForegroundColor $(if ($driftCount -gt 0) { 'Red' } else { 'Green' })

    # 步骤 4: 自动修正（如果启用）
    if ($driftCount -gt 0 -and $AutoRemediate) {
        Write-Host "`n[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')] 正在执行自动修正..." -ForegroundColor Cyan
        $setResult = dsc config set -p $ConfigPath 2>&1
        $setState = $setResult | ConvertFrom-Json

        $remediated = 0
        foreach ($resource in $setState.results) {
            if ($resource.rebootRequired) {
                Write-Host ("  [注意] {0}[{1}] 需要重启" -f @(
                    $resource.type, $resource.name
                )) -ForegroundColor Magenta
            }
            $remediated++
        }

        Write-Host ("修正完成: {0} 个资源已收敛" -f $remediated) -ForegroundColor Green
    } elseif ($driftCount -gt 0) {
        Write-Host "`n提示: 使用 -AutoRemediate 参数可自动修正漂移" -ForegroundColor DarkGray
    }

    Write-Host "=================================="

    # 返回结构化报告
    return $report
}

# 执行漂移检测（仅检测，不修正）
$serverConfig = Join-Path $env:TEMP 'dsc-v3-server-config.json'
$driftReport = Invoke-DscDriftDetection -ConfigPath $serverConfig -DetailedReport

# 将漂移报告导出为 JSON（供 CI/CD 流水线消费）
$reportPath = Join-Path $env:TEMP "drift-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$driftReport | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8
Write-Host "`n漂移报告已导出至: $reportPath"
```

执行结果示例：

```
[2026-01-06T10:30:15+08:00] 正在获取当前配置状态...
[2026-01-06T10:30:17+08:00] 正在检测配置漂移...
  [漂移] Microsoft.Windows/Registry[EnableLongPaths]: 状态不匹配
  [合规] Microsoft.Windows/Feature[InstallSSH]
  [合规] Microsoft/Process[EnsureSSHService]

========== 配置漂移报告 ==========
检测时间: 2026-01-06T10:30:17+08:00
配置文件: /tmp/dsc-v3-server-config.json
资源总数: 3
合规数量: 2
漂移数量: 1
提示: 使用 -AutoRemediate 参数可自动修正漂移
==================================

漂移报告已导出至: /tmp/drift-report-20260106-103017.json
```

## 注意事项

1. **DSC v3 需要独立安装**：DSC v3 是独立的原生可执行文件（`dsc`），不随 PowerShell 自带。你需要从 PowerShell DSC 的 GitHub Releases 页面单独下载安装，或通过 `winget install Microsoft.DSC` 获取。

2. **JSON Schema 验证很重要**：编写配置文档时务必引用官方 JSON Schema。大多数现代编辑器（VS Code、JetBrains）能根据 `$schema` 字段提供智能提示和实时校验，大幅减少语法错误。在应用到生产环境前，始终先运行 `dsc config validate`。

3. **自定义资源的幂等性**：自定义资源必须确保 `set` 操作的幂等性——即多次执行结果一致。在 `test` 操作中精确比较期望状态与实际状态，避免产生不必要的修正操作。对于复杂属性，建议逐字段对比而非整体序列化比较。

4. **配置漂移报告纳入 CI/CD**：将漂移检测集成到 CI/CD 流水线中，每次配置变更都自动触发漂移检测。`-AutoRemediate` 参数在生产环境使用时应格外谨慎，建议先以只读模式运行检测，人工确认漂移报告后再执行修正。

5. **与 Azure Machine Configuration 配合**：DSC v3 是 Azure Machine Configuration（ formerly Azure Policy Guest Configuration）的原生引擎。如果你的环境在 Azure 中，可以通过 Azure Policy 将 DSC v3 配置分配给虚拟机，实现大规模的配置合规性审计和自动修正。

6. **版本管理配置文档**：配置文档应纳入 Git 版本控制，通过 Pull Request 审核配置变更。建议在仓库中设置 `dsc config validate` 作为 pre-commit hook，确保每次提交的配置文档都是合法的。同时保留历史配置版本，便于回滚和变更追溯。
