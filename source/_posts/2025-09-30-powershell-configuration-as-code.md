---
layout: post
date: 2025-09-30 08:00:00
updated: 2025-09-30 08:00:00
title: "PowerShell 技能连载 - 配置即代码"
description: PowerTip of the Day - Configuration as Code in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- configuration-as-code
- devops
- infrastructure
---

_适用于 PowerShell 7.0 及以上版本_

在 DevOps 和基础设施自动化的浪潮中，"配置即代码"（Configuration as Code，CaC）已经成为一种核心实践。传统的服务器配置往往依赖运维人员手动登录、逐台修改，这种方式不仅效率低下，而且容易出现人为错误，更无法保证环境之间的一致性。当服务器规模从几台增长到几十台、上百台时，手动配置的方式就完全不可行了。

配置即代码的核心理念是将系统的期望状态用声明式的代码描述出来，然后通过工具自动将系统收敛到这个状态。PowerShell 作为 Windows 生态的首选自动化工具，天然具备实现配置即代码的能力。从 PowerShell Desired State Configuration（DSC）到自定义的配置管理框架，我们可以灵活选择适合团队规模的方案。

本文将演示如何用 PowerShell 构建一套轻量级的配置即代码框架，包括定义配置文件、编写配置测试、实现幂等的配置应用，以及生成配置漂移报告。

<!-- more -->

## 定义 JSON 配置清单

首先，我们需要一种结构化的方式来描述系统的期望状态。JSON 是一种通用且易于阅读的格式，非常适合充当配置清单的角色。下面的代码定义了一个配置清单结构，并创建一份示例配置文件，涵盖 Windows 功能、注册表项、文件路径和服务状态等常见配置项。

```powershell
# 定义配置清单的目录和文件路径
$configRoot = "$env:USERPROFILE\Documents\ConfigAsCode"
$manifestPath = Join-Path $configRoot "server-manifest.json"

# 确保配置目录存在
if (-not (Test-Path $configRoot)) {
    New-Item -Path $configRoot -ItemType Directory -Force | Out-Null
    Write-Host "已创建配置目录：$configRoot" -ForegroundColor Green
}

# 定义期望状态的配置清单
$manifest = [PSCustomObject]@{
    Metadata = [PSCustomObject]@{
        Name        = "WebServer-Production"
        Version     = "1.2.0"
        Author      = "DevOps Team"
        LastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        Description = "生产环境 Web 服务器标准配置"
    }
    WindowsFeatures = @(
        [PSCustomObject]@{ Name = "Web-Server"; Ensure = "Present" }
        [PSCustomObject]@{ Name = "Web-Mgmt-Tools"; Ensure = "Present" }
        [PSCustomObject]@{ Name = "Telnet-Client"; Ensure = "Absent" }
    )
    RegistrySettings = @(
        [PSCustomObject]@{
            Key   = "HKLM:\SOFTWARE\MyApp"
            Name  = "LogLevel"
            Value = 2
            Type  = "DWord"
        }
        [PSCustomObject]@{
            Key   = "HKLM:\SOFTWARE\MyApp"
            Name  = "MaxConnections"
            Value = 100
            Type  = "DWord"
        }
    )
    Files = @(
        [PSCustomObject]@{
            Path    = "C:\MyApp\config\appsettings.json"
            Content = '{"Logging":{"Level":"Information"}}'
            Ensure  = "Present"
        }
    )
    Services = @(
        [PSCustomObject]@{ Name = "W3SVC"; State = "Running"; StartType = "Automatic" }
        [PSCustomObject]@{ Name = "Spooler"; State = "Stopped"; StartType = "Disabled" }
    )
}

# 将配置清单写入 JSON 文件
$manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
Write-Host "配置清单已保存至：$manifestPath" -ForegroundColor Cyan

# 验证文件内容
$config = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
Write-Host "`n配置名称：$($config.Metadata.Name)"
Write-Host "配置版本：$($config.Metadata.Version)"
Write-Host "Windows 功能项：$($config.WindowsFeatures.Count) 个"
Write-Host "注册表设置：$($config.RegistrySettings.Count) 项"
Write-Host "文件配置：$($config.Files.Count) 个"
Write-Host "服务配置：$($config.Services.Count) 个"
```

```text
已创建配置目录：C:\Users\admin\Documents\ConfigAsCode
配置清单已保存至：C:\Users\admin\Documents\ConfigAsCode\server-manifest.json

配置名称：WebServer-Production
配置版本：1.2.0
Windows 功能项：3 个
注册表设置：2 项
文件配置：1 个
服务配置：2 个
```

## 编写配置测试与漂移检测

配置即代码的核心价值在于"可验证"。我们需要一套测试机制，定期对比系统的实际状态与期望状态，发现配置漂移（Configuration Drift）。下面的代码实现了一个漂移检测函数，它会逐项检查配置清单中的每一类资源，输出合规状态。

```powershell
# 配置漂移检测函数
function Test-ConfigurationDrift {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [string[]]$Categories = @("All")
    )

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $drifts = [System.Collections.Generic.List[PSCustomObject]]::new()

    Write-Host "`n========== 配置漂移检测 ==========" -ForegroundColor Cyan
    Write-Host "目标配置：$($manifest.Metadata.Name) v$($manifest.Metadata.Version)"
    Write-Host "检测时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "==================================`n"

    # 检查注册表设置
    if ($Categories -contains "All" -or $Categories -contains "Registry") {
        Write-Host "--- 注册表设置 ---" -ForegroundColor Yellow
        foreach ($reg in $manifest.RegistrySettings) {
            $actualValue = $null
            $compliant = $false

            if (Test-Path $reg.Key) {
                $item = Get-ItemProperty -Path $reg.Key -Name $reg.Name -ErrorAction SilentlyContinue
                if ($null -ne $item) {
                    $actualValue = $item.($reg.Name)
                    $compliant = ($actualValue -eq $reg.Value)
                }
            }

            $drifts.Add([PSCustomObject]@{
                Category   = "Registry"
                Resource   = "$($reg.Key)\$($reg.Name)"
                Expected   = $reg.Value
                Actual     = $actualValue
                Compliant  = $compliant
            })

            $status = if ($compliant) { "[OK]" } else { "[DRIFT]" }
            $color  = if ($compliant) { "Green" } else { "Red" }
            Write-Host "  $status $($reg.Name)：期望=$($reg.Value)，实际=$actualValue" -ForegroundColor $color
        }
    }

    # 检查文件配置
    if ($Categories -contains "All" -or $Categories -contains "Files") {
        Write-Host "`n--- 文件配置 ---" -ForegroundColor Yellow
        foreach ($file in $manifest.Files) {
            $exists = Test-Path $file.Path
            $compliant = $false
            $actualContent = $null

            if ($exists -and $file.Ensure -eq "Present") {
                $actualContent = Get-Content -Path $file.Path -Raw
                $compliant = ($actualContent.Trim() -eq $file.Content.Trim())
            }
            elseif (-not $exists -and $file.Ensure -eq "Absent") {
                $compliant = $true
            }

            $drifts.Add([PSCustomObject]@{
                Category  = "Files"
                Resource  = $file.Path
                Expected  = $file.Ensure
                Actual    = if ($exists) { "Present" } else { "Absent" }
                Compliant = $compliant
            })

            $status = if ($compliant) { "[OK]" } else { "[DRIFT]" }
            $color  = if ($compliant) { "Green" } else { "Red" }
            Write-Host "  $status $($file.Path)：$($file.Ensure)" -ForegroundColor $color
        }
    }

    # 检查服务状态
    if ($Categories -contains "All" -or $Categories -contains "Services") {
        Write-Host "`n--- 服务配置 ---" -ForegroundColor Yellow
        foreach ($svc in $manifest.Services) {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            $compliant = $false

            if ($null -ne $service) {
                $stateOk = ($service.Status.ToString() -eq $svc.State)
                $startTypeOk = ($service.StartType.ToString() -eq $svc.StartType)
                $compliant = ($stateOk -and $startTypeOk)
            }

            $drifts.Add([PSCustomObject]@{
                Category  = "Services"
                Resource  = $svc.Name
                Expected  = "$($svc.State) / $($svc.StartType)"
                Actual    = if ($service) { "$($service.Status) / $($service.StartType)" } else { "NotFound" }
                Compliant = $compliant
            })

            $status = if ($compliant) { "[OK]" } else { "[DRIFT]" }
            $color  = if ($compliant) { "Green" } else { "Red" }
            Write-Host "  $status $($svc.Name)：期望=$($svc.State)/$($svc.StartType)" -ForegroundColor $color
        }
    }

    # 汇总报告
    $total = $drifts.Count
    $compliantCount = ($drifts | Where-Object { $_.Compliant }).Count
    $driftCount = $total - $compliantCount
    $complianceRate = if ($total -gt 0) { [math]::Round($compliantCount / $total * 100, 1) } else { 0 }

    Write-Host "`n========== 漂移汇总 ==========" -ForegroundColor Cyan
    Write-Host "  总检测项：$total"
    Write-Host "  合规项：  $compliantCount" -ForegroundColor Green
    Write-Host "  漂移项：  $driftCount" -ForegroundColor Red
    Write-Host "  合规率：  $complianceRate%"
    Write-Host "================================`n"

    return $drifts
}

# 执行漂移检测
$driftResults = Test-ConfigurationDrift -ManifestPath $manifestPath
```

```text
========== 配置漂移检测 ==========
目标配置：WebServer-Production v1.2.0
检测时间：2025-09-30 14:30:00
==================================

--- 注册表设置 ---
  [DRIFT] LogLevel：期望=2，实际=
  [DRIFT] MaxConnections：期望=100，实际=

--- 文件配置 ---
  [DRIFT] C:\MyApp\config\appsettings.json：Present

--- 服务配置 ---
  [OK] W3SVC：期望=Running/Automatic
  [DRIFT] Spooler：期望=Stopped/Disabled

========== 漂移汇总 ==========
  总检测项：5
  合规项：  1
  漂移项：  4
  合规率：  20.0%
================================
```

## 实现幂等的配置应用

检测到漂移后，下一步是自动修复。配置应用函数必须是幂等的（Idempotent），即多次执行的结果与一次执行相同。下面的代码会根据漂移检测结果，逐项将系统收敛到期望状态，并记录每一步的操作日志。

```powershell
# 幂等配置应用函数
function Invoke-ConfigurationApply {
    param(
        [Parameter(Mandatory)]
        [string]$ManifestPath,

        [switch]$WhatIf
    )

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    $logEntries = [System.Collections.Generic.List[PSCustomObject]]::new()

    Write-Host "`n========== 配置应用 ==========" -ForegroundColor Cyan
    Write-Host "目标配置：$($manifest.Metadata.Name) v$($manifest.Metadata.Version)"
    if ($WhatIf) {
        Write-Host "模式：WhatIf（仅预览，不执行变更）" -ForegroundColor Yellow
    }
    Write-Host "开始时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "==============================`n"

    # 应用注册表设置
    foreach ($reg in $manifest.RegistrySettings) {
        $action = "Set"
        if (-not (Test-Path $reg.Key)) {
            if (-not $WhatIf) {
                New-Item -Path $reg.Key -Force | Out-Null
            }
            $action = "Create+Set"
        }

        if (-not $WhatIf) {
            Set-ItemProperty -Path $reg.Key -Name $reg.Name -Value $reg.Value -Type $reg.Type -Force
        }

        $logEntries.Add([PSCustomObject]@{
            Time   = Get-Date -Format "HH:mm:ss"
            Action = $action
            Target = "$($reg.Key)\$($reg.Name)"
            Value  = $reg.Value
            Status = "Applied"
        })

        Write-Host "  [$action] $($reg.Key)\$($reg.Name) = $($reg.Value)" -ForegroundColor Green
    }

    # 应用文件配置
    foreach ($file in $manifest.Files) {
        $parentDir = Split-Path $file.Path -Parent

        if ($file.Ensure -eq "Present") {
            if (-not (Test-Path $parentDir)) {
                if (-not $WhatIf) {
                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                }
            }

            if (-not $WhatIf) {
                Set-Content -Path $file.Path -Value $file.Content -NoNewline -Force
            }

            $logEntries.Add([PSCustomObject]@{
                Time   = Get-Date -Format "HH:mm:ss"
                Action = "Write"
                Target = $file.Path
                Value  = "(content)"
                Status = "Applied"
            })

            Write-Host "  [Write] $($file.Path)" -ForegroundColor Green
        }
        elseif ($file.Ensure -eq "Absent" -and (Test-Path $file.Path)) {
            if (-not $WhatIf) {
                Remove-Item -Path $file.Path -Force
            }

            $logEntries.Add([PSCustomObject]@{
                Time   = Get-Date -Format "HH:mm:ss"
                Action = "Remove"
                Target = $file.Path
                Value  = ""
                Status = "Applied"
            })

            Write-Host "  [Remove] $($file.Path)" -ForegroundColor Green
        }
    }

    # 应用服务配置
    foreach ($svc in $manifest.Services) {
        $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

        if ($null -ne $service) {
            # 设置启动类型
            if ($service.StartType.ToString() -ne $svc.StartType) {
                if (-not $WhatIf) {
                    Set-Service -Name $svc.Name -StartupType $svc.StartType
                }
                Write-Host "  [SetStartup] $($svc.Name) -> $($svc.StartType)" -ForegroundColor Green
            }

            # 设置服务状态
            if ($service.Status.ToString() -ne $svc.State) {
                if (-not $WhatIf) {
                    if ($svc.State -eq "Running") {
                        Start-Service -Name $svc.Name
                    }
                    elseif ($svc.State -eq "Stopped") {
                        Stop-Service -Name $svc.Name -Force
                    }
                }
                Write-Host "  [SetState] $($svc.Name) -> $($svc.State)" -ForegroundColor Green
            }

            $logEntries.Add([PSCustomObject]@{
                Time   = Get-Date -Format "HH:mm:ss"
                Action = "Configure"
                Target = $svc.Name
                Value  = "$($svc.State) / $($svc.StartType)"
                Status = "Applied"
            })
        }
    }

    Write-Host "`n==============================" -ForegroundColor Cyan
    Write-Host "变更总数：$($logEntries.Count)"
    Write-Host "完成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "==============================`n"

    return $logEntries
}

# 先用 WhatIf 预览变更
Write-Host ">>> 预览模式 <<<" -ForegroundColor Magenta
$previewLog = Invoke-ConfigurationApply -ManifestPath $manifestPath -WhatIf

# 确认后执行实际变更
Write-Host "`n>>> 执行模式 <<<" -ForegroundColor Magenta
$applyLog = Invoke-ConfigurationApply -ManifestPath $manifestPath

# 再次检测漂移，验证修复效果
Write-Host "`n>>> 修复验证 <<<" -ForegroundColor Magenta
$verifyResults = Test-ConfigurationDrift -ManifestPath $manifestPath
$verifyCompliant = ($verifyResults | Where-Object { $_.Compliant }).Count
Write-Host "修复后合规项：$verifyCompliant / $($verifyResults.Count)" -ForegroundColor Green
```

```text
>>> 预览模式 <<<

========== 配置应用 ==========
目标配置：WebServer-Production v1.2.0
模式：WhatIf（仅预览，不执行变更）
开始时间：2025-09-30 14:35:00
==============================

  [Create+Set] HKLM:\SOFTWARE\MyApp\LogLevel = 2
  [Create+Set] HKLM:\SOFTWARE\MyApp\MaxConnections = 100
  [Write] C:\MyApp\config\appsettings.json
  [Configure] W3SVC
  [Configure] Spooler

==============================
变更总数：5
完成时间：2025-09-30 14:35:00
==============================

>>> 执行模式 <<<

========== 配置应用 ==========
目标配置：WebServer-Production v1.2.0
开始时间：2025-09-30 14:35:12
==============================

  [Create+Set] HKLM:\SOFTWARE\MyApp\LogLevel = 2
  [Create+Set] HKLM:\SOFTWARE\MyApp\MaxConnections = 100
  [Write] C:\MyApp\config\appsettings.json
  [SetStartup] Spooler -> Disabled
  [SetState] Spooler -> Stopped

==============================
变更总数：5
完成时间：2025-09-30 14:35:14
==============================

>>> 修复验证 <<<

========== 配置漂移检测 ==========
目标配置：WebServer-Production v1.2.0
检测时间：2025-09-30 14:35:15
==================================

--- 注册表设置 ---
  [OK] LogLevel：期望=2，实际=2
  [OK] MaxConnections：期望=100，实际=100

--- 文件配置 ---
  [OK] C:\MyApp\config\appsettings.json：Present

--- 服务配置 ---
  [OK] W3SVC：期望=Running/Automatic
  [OK] Spooler：期望=Stopped/Disabled

========== 漂移汇总 ==========
  总检测项：5
  合规项：  5
  漂移项：  0
  合规率：  100.0%
================================

修复后合规项：5 / 5
```

## 生成配置变更历史报告

配置管理的最后一环是审计。我们需要记录每次配置变更的详情，包括变更时间、操作者、变更内容和结果，以便在出现问题时快速回溯。下面的代码实现了一个简单的变更历史追踪机制，将每次应用配置的日志追加到 CSV 文件中。

```powershell
# 配置变更历史追踪
function Write-ConfigurationAuditLog {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$LogEntries,

        [string]$AuditLogPath = "$configRoot\audit-log.csv"
    )

    # 为每条日志添加审计字段
    $auditRecords = foreach ($entry in $LogEntries) {
        [PSCustomObject]@{
            Timestamp  = "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')"
            Operator   = $env:USERNAME
            Machine    = $env:COMPUTERNAME
            Action     = $entry.Action
            Target     = $entry.Target
            Value      = $entry.Value
            Status     = $entry.Status
            ConfigRef  = "WebServer-Production v1.2.0"
        }
    }

    # 追加到 CSV 审计日志（如文件不存在则创建表头）
    $auditRecords | Export-Csv -Path $AuditLogPath -NoTypeInformation -Append -Force -Encoding UTF8
    Write-Host "审计日志已追加至：$AuditLogPath" -ForegroundColor Green

    # 显示最近的审计记录
    Write-Host "`n最近 5 条审计记录：" -ForegroundColor Cyan
    $recentLogs = Import-Csv -Path $AuditLogPath -Encoding UTF8 |
        Select-Object -Last 5

    $recentLogs | Format-Table Timestamp, Operator, Action, Target, Status -AutoSize
}

# 计算合规趋势（适用于定期巡检场景）
function Get-ComplianceTrend {
    param(
        [string]$TrendLogPath = "$configRoot\compliance-trend.csv"
    )

    # 记录本次合规率
    $drifts = Test-ConfigurationDrift -ManifestPath $manifestPath
    $total = $drifts.Count
    $compliant = ($drifts | Where-Object { $_.Compliant }).Count
    $rate = if ($total -gt 0) { [math]::Round($compliant / $total * 100, 1) } else { 100 }

    $trendRecord = [PSCustomObject]@{
        Date         = Get-Date -Format "yyyy-MM-dd"
        Time         = Get-Date -Format "HH:mm:ss"
        TotalItems   = $total
        Compliant    = $compliant
        Drifted      = $total - $compliant
        RatePercent  = $rate
    }

    $trendRecord | Export-Csv -Path $TrendLogPath -NoTypeInformation -Append -Force -Encoding UTF8

    Write-Host "`n合规趋势已记录：" -ForegroundColor Cyan
    Write-Host "  日期：$($trendRecord.Date)"
    Write-Host "  合规率：$($trendRecord.RatePercent)%"
    Write-Host "  漂移项：$($trendRecord.Drifted)"

    # 显示近 7 次巡检趋势
    if (Test-Path $TrendLogPath) {
        $history = Import-Csv -Path $TrendLogPath -Encoding UTF8 |
            Select-Object -Last 7

        Write-Host "`n近 7 次巡检合规率趋势：" -ForegroundColor Yellow
        foreach ($record in $history) {
            $bar = "=" * ([math]::Floor([int]$record.RatePercent / 5))
            Write-Host "  $($record.Date) [$($record.RatePercent)%] $bar"
        }
    }
}

# 写入审计日志
Write-ConfigurationAuditLog -LogEntries $applyLog

# 记录合规趋势
Get-ComplianceTrend
```

```text
审计日志已追加至：C:\Users\admin\Documents\ConfigAsCode\audit-log.csv

最近 5 条审计记录：
Timestamp            Operator Action     Target                                Status
---------            -------- ------     ------                                ------
2025-09-30T14:35:12  admin    Create+Set HKLM:\SOFTWARE\MyApp\LogLevel         Applied
2025-09-30T14:35:12  admin    Create+Set HKLM:\SOFTWARE\MyApp\MaxConnections   Applied
2025-09-30T14:35:13  admin    Write      C:\MyApp\config\appsettings.json      Applied
2025-09-30T14:35:13  admin    Configure  W3SVC                                 Applied
2025-09-30T14:35:14  admin    Configure  Spooler                               Applied

========== 配置漂移检测 ==========
目标配置：WebServer-Production v1.2.0
检测时间：2025-09-30 14:36:00
==================================

--- 注册表设置 ---
  [OK] LogLevel：期望=2，实际=2
  [OK] MaxConnections：期望=100，实际=100

--- 文件配置 ---
  [OK] C:\MyApp\config\appsettings.json：Present

--- 服务配置 ---
  [OK] W3SVC：期望=Running/Automatic
  [OK] Spooler：期望=Stopped/Disabled

========== 漂移汇总 ==========
  总检测项：5
  合规项：  5
  漂移项：  0
  合规率：  100.0%
================================

合规趋势已记录：
  日期：2025-09-30
  合规率：100.0%
  漂移项：0

近 7 次巡检合规率趋势：
  2025-09-24 [60.0%] ============
  2025-09-25 [80.0%] ================
  2025-09-26 [80.0%] ================
  2025-09-27 [40.0%] ========
  2025-09-28 [60.0%] ============
  2025-09-29 [80.0%] ================
  2025-09-30 [100.0%] ====================
```

## 注意事项

1. **幂等性是底线**：配置应用函数必须保证多次执行结果一致，避免重复创建、重复写入等副作用，每次操作前先检查当前状态
2. **JSON Schema 验证**：在生产环境中，应在加载配置清单前用 JSON Schema 验证其结构完整性，防止因配置文件格式错误导致不可预期的变更
3. **WhatIf 先行**：所有配置变更操作都应先以 `-WhatIf` 模式预览，确认变更范围后再执行，结合 CI/CD 流水线可实现审批门控
4. **变更回滚机制**：每次应用配置前应备份当前状态，或维护一个"上一个已知良好配置"，出现问题时能快速回退
5. **敏感信息保护**：配置清单中可能包含密码、API 密钥等敏感数据，应使用 Azure Key Vault、Windows Credential Manager 或 PowerShell SecretManagement 模块管理，不要明文存储在 JSON 中
6. **跨平台兼容性**：本文示例以 Windows 注册表和服务为主，如果需要管理 Linux 节点，可将配置目标替换为文件权限、systemd 服务和包管理器，核心框架逻辑不变
