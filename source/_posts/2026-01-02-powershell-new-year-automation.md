---
layout: post
date: 2026-01-02 08:00:00
updated: 2026-01-02 08:00:00
title: "PowerShell 技能连载 - 新年自动化脚本"
description: PowerTip of the Day - New Year Automation Scripts in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- automation
- best-practices
---

_适用于 PowerShell 5.1 及以上版本_

新年伊始，系统管理员面临着一系列"开年"初始化任务：更新所有自动化脚本的版权年份、重置年度计数器和统计数据、创建新的日志目录结构、部署第一季度的安全基线检查。这些琐碎但重要的工作如果逐一手动完成，不仅耗时，还容易遗漏关键环节，给后续全年运行埋下隐患。

更麻烦的是，这些任务往往分散在不同的服务器和项目目录中。脚本可能分布在几十个仓库里，日志配置文件散落在多台服务器上，计划任务的调度时间需要按新年度重新校准。手动逐一排查和更新，不仅效率低下，而且很难保证一致性——某台服务器忘了更新目录，某份脚本的年份还是去年的，这些疏忽往往要到年中出问题时才被发现。

通过 PowerShell 脚本将这些"开年"任务编排为一套可一键执行的自动化流程，可以确保所有初始化工作在统一的控制下完成，每一步都有日志记录、有结果校验。本文将从年度环境初始化、安全基线审计、全年计划任务部署三个维度，展示如何用 PowerShell 高效完成新年开局工作。

<!-- more -->

## 年度环境初始化

新年第一天要做的第一件事就是为全年运维准备好基础环境。下面的脚本会批量创建年度日志目录结构、重置 JSON 配置文件中的计数器、并自动更新所有脚本文件头部的版权年份。

```powershell
function Initialize-NewYearEnvironment {
    <#
    .SYNOPSIS
    执行新年环境初始化：创建目录、重置计数器、更新版权年份
    .PARAMETER Year
    目标年份，默认为当前年份
    .PARAMETER LogBasePath
    日志根目录路径
    .PARAMETER ConfigPath
    年度配置 JSON 文件路径
    #>
    param(
        [int]$Year = (Get-Date).Year,
        [string]$LogBasePath = "C:\Logs",
        [string]$ConfigPath = "C:\Scripts\config\annual-config.json"
    )

    $results = @()

    # ---- 1. 创建年度日志目录结构（按月和类别） ----
    $categories = @("System", "Security", "Application", "Backup", "Audit")
    $createdDirs = @()

    foreach ($category in $categories) {
        1..12 | ForEach-Object {
            $month = "{0:D2}" -f $_
            $dirPath = Join-Path $LogBasePath "$Year\$category\$month"
            if (-not (Test-Path $dirPath)) {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                $createdDirs += $dirPath
            }
        }
    }
    $results += "[目录] 已创建 $($createdDirs.Count) 个日志目录 ($LogBasePath\$Year\)"

    # ---- 2. 重置年度配置计数器 ----
    if (Test-Path $ConfigPath) {
        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # 重置核心计数器
        $config.Year = $Year
        $config.Counters.IncidentNumber = 0
        $config.Counters.ChangeRequestNumber = 0
        $config.Counters.BackupJobCount = 0
        $config.Counters.LastResetDate = (Get-Date -Format "yyyy-MM-dd")
        $config.Counters.PreviousYearTotal = $config.Counters.YearlyTotal
        $config.Counters.YearlyTotal = 0

        # 更新维护窗口配置
        $config.MaintenanceWindows.NextScheduled = "$Year-01-05T02:00:00"

        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        $results += "[配置] 已重置年度计数器: $ConfigPath"
    } else {
        # 首次运行，创建默认配置
        $defaultConfig = [PSCustomObject]@{
            Year = $Year
            Counters = @{
                IncidentNumber = 0
                ChangeRequestNumber = 0
                BackupJobCount = 0
                YearlyTotal = 0
                PreviousYearTotal = 0
                LastResetDate = (Get-Date -Format "yyyy-MM-dd")
            }
            MaintenanceWindows = @{
                NextScheduled = "$Year-01-05T02:00:00"
                DefaultDurationHours = 4
            }
        }
        $dirName = Split-Path $ConfigPath -Parent
        if (-not (Test-Path $dirName)) {
            New-Item -Path $dirName -ItemType Directory -Force | Out-Null
        }
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
        $results += "[配置] 已创建默认年度配置: $ConfigPath"
    }

    # ---- 3. 批量更新脚本文件的版权年份 ----
    $scriptPaths = @(
        "C:\Scripts\Automation\*.ps1"
        "C:\Scripts\Maintenance\*.ps1"
        "C:\Scripts\Monitoring\*.ps1"
    )

    $updatedFiles = 0
    $oldYear = $Year - 1
    foreach ($path in $scriptPaths) {
        if (Test-Path (Split-Path $path)) {
            Get-ChildItem -Path $path -File | ForEach-Object {
                $content = Get-Content $_.FullName -Raw -Encoding UTF8
                if ($content -match "Copyright.*$oldYear") {
                    $content = $content -replace "(Copyright\s*(?:\(c\)\s*)?)$oldYear", "`${1}$Year"
                    Set-Content -Path $_.FullName -Value $content -Encoding UTF8 -NoNewline
                    $updatedFiles++
                }
            }
        }
    }
    $results += "[版权] 已更新 $updatedFiles 个脚本的版权年份 ($oldYear -> $Year)"

    # ---- 4. 输出初始化报告 ----
    $summary = [PSCustomObject]@{
        初始化年份 = $Year
        执行时间 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        创建目录数 = $createdDirs.Count
        更新文件数 = $updatedFiles
        配置文件 = $ConfigPath
    }

    Write-Host "`n=== 新年环境初始化完成 ===" -ForegroundColor Green
    $results | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    Write-Host ""
    return $summary
}

# 执行 2026 年环境初始化
$initResult = Initialize-NewYearEnvironment -Year 2026
$initResult | Format-List
```

执行结果示例：

```
=== 新年环境初始化完成 ===
  [目录] 已创建 60 个日志目录 (C:\Logs\2026\)
  [配置] 已重置年度计数器: C:\Scripts\config\annual-config.json
  [版权] 已更新 23 个脚本的版权年份 (2025 -> 2026)

初始化年份 : 2026
执行时间   : 2026-01-02 09:15:32
创建目录数 : 60
更新文件数 : 23
配置文件   : C:\Scripts\config\annual-config.json
```

脚本中的目录结构采用"年份/类别/月份"三层组织方式，方便后续按时间和类型快速定位日志。版权年份更新通过正则表达式精确匹配，避免误改文件内容中的其他数字。配置计数器重置时会保留去年的累计值到 `PreviousYearTotal` 字段，用于年度间的对比分析。

## 安全基线审计

新年伊始是进行全面安全基线审计的最佳时机。下面的脚本会检查密码策略合规性、扫描服务账户的密码过期状态、并排查所有证书的到期时间，为全年安全工作打好基础。

```powershell
function Invoke-NewYearSecurityAudit {
    <#
    .SYNOPSIS
    执行新年安全基线审计：密码策略、服务账户、证书到期
    .PARAMETER DomainName
    Active Directory 域名，为空则检查本地安全策略
    .PARAMETER CertWarningDays
    证书到期提前告警天数，默认 90 天
    #>
    param(
        [string]$DomainName,
        [int]$CertWarningDays = 90
    )

    $auditTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $findings = @()
    $criticalCount = 0
    $warningCount = 0

    # ---- 1. 密码策略审计 ----
    Write-Host "`n[1/3] 正在检查密码策略..." -ForegroundColor Yellow

    try {
        if ($DomainName) {
            $secPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $DomainName -ErrorAction Stop
            $policy = [PSCustomObject]@{
                最小密码长度 = $secPolicy.MinPasswordLength
                密码最长期限天 = $secPolicy.MaxPasswordAge.Days
                密码最短期限天 = $secPolicy.MinPasswordAge.Days
                密码历史记录数 = $secPolicy.PasswordHistoryCount
                账户锁定阈值 = $secPolicy.LockoutThreshold
                锁定持续时间分 = $secPolicy.LockoutDuration.TotalMinutes
            }
        } else {
            # 本地安全策略通过 secedit 导出分析
            $tempDb = Join-Path $env:TEMP "secedit-$(Get-Random).sdb"
            $tempCfg = Join-Path $env:TEMP "secedit-$(Get-Random).cfg"
            $tempInf = Join-Path $env:TEMP "secedit-$(Get-Random).inf"

            secedit /export /cfg $tempCfg /quiet 2>$null
            $policyContent = Get-Content $tempCfg -Encoding Unicode -ErrorAction SilentlyContinue

            $minLen = ($policyContent | Select-String "MinimumPasswordLength").ToString().Split("=")[-1].Trim()
            $maxAge = ($policyContent | Select-String "MaximumPasswordAge").ToString().Split("=")[-1].Trim()

            $policy = [PSCustomObject]@{
                最小密码长度 = [int]$minLen
                密码最长期限天 = [int]$maxAge
                密码最短期限天 = "N/A (本地策略)"
                密码历史记录数 = "N/A (本地策略)"
                账户锁定阈值 = "N/A (本地策略)"
                锁定持续时间分 = "N/A (本地策略)"
            }

            Remove-Item $tempCfg -Force -ErrorAction SilentlyContinue
        }

        # 检查合规性
        if ($policy.最小密码长度 -lt 12) {
            $findings += "[严重] 密码最小长度为 $($policy.最小密码Length) 位，建议至少 12 位"
            $criticalCount++
        }
        if ($policy.密码最长期限天 -gt 90 -or $policy.密码最长期限天 -eq 0) {
            $findings += "[警告] 密码最长期限为 $($policy.密码最长期限天) 天，建议不超过 90 天"
            $warningCount++
        }
    } catch {
        $findings += "[信息] 无法读取密码策略: $($_.Exception.Message)"
    }

    # ---- 2. 服务账户密码过期检查 ----
    Write-Host "[2/3] 正在检查服务账户状态..." -ForegroundColor Yellow

    try {
        if ($DomainName) {
            $serviceAccounts = Get-ADUser -Filter {
                Enabled -eq $true -and PasswordNeverExpires -eq $true
            } -Properties Name, SamAccountName, PasswordLastSet, LastLogonDate -ErrorAction Stop

            foreach ($acct in $serviceAccounts) {
                $daysSincePwdSet = if ($acct.PasswordLastSet) {
                    ((Get-Date) - $acct.PasswordLastSet).Days
                } else { -1 }

                if ($daysSincePwdSet -gt 365 -or $daysSincePwdSet -eq -1) {
                    $status = if ($daysSincePwdSet -eq -1) { "从未设置" } else { "$daysSincePwdSet 天" }
                    $findings += "[警告] 服务账户 $($acct.SamAccountName) 密码已 $status 未更新 (密码永不过期)"
                    $warningCount++
                }
            }
            $findings += "[信息] 发现 $($serviceAccounts.Count) 个设置了'密码永不过期'的账户"
        } else {
            # 本地检查：获取非内置的本地用户
            $localUsers = Get-LocalUser | Where-Object {
                $_.Enabled -and $_.PasswordNeverExpires -and $_.Name -notmatch "^(Administrator|Guest|DefaultAccount|WDAGUtilityAccount)$"
            }

            foreach ($user in $localUsers) {
                $findings += "[警告] 本地用户 $($user.Name) 设置了密码永不过期"
                $warningCount++
            }
        }
    } catch {
        $findings += "[信息] 服务账户检查受限: $($_.Exception.Message)"
    }

    # ---- 3. 证书到期扫描 ----
    Write-Host "[3/3] 正在扫描证书到期时间..." -ForegroundColor Yellow

    $certStores = @("Cert:\LocalMachine\My", "Cert:\LocalMachine\Root")
    $expiringCerts = @()

    foreach ($store in $certStores) {
        if (Test-Path $store) {
            Get-ChildItem $store | ForEach-Object {
                $daysUntilExpiry = ($_.NotAfter - (Get-Date)).Days
                if ($daysUntilExpiry -le $CertWarningDays) {
                    $severity = if ($daysUntilExpiry -le 0) { "已过期" } elseif ($daysUntilExpiry -le 30) { "即将过期" } else { "即将到期" }
                    $expiringCerts += [PSCustomObject]@{
                        严重程度 = $severity
                        剩余天数 = $daysUntilExpiry
                        主题 = $_.Subject
                        到期时间 = $_.NotAfter.ToString("yyyy-MM-dd")
                        指纹 = $_.Thumbprint.Substring(0, 8) + "..."
                    }

                    if ($daysUntilExpiry -le 0) {
                        $criticalCount++
                    } else {
                        $warningCount++
                    }
                }
            }
        }
    }

    if ($expiringCerts.Count -gt 0) {
        $findings += "[证书] 发现 $($expiringCerts.Count) 个需要关注的证书:"
        $expiringCerts | Sort-Object 剩余天数 | ForEach-Object {
            $findings += "  - [$($_.严重程度)] $($_.主题) (剩余 $($_.剩余天数) 天, 到期 $($_.到期时间))"
        }
    } else {
        $findings += "[证书] 未发现即将到期的证书 ($CertWarningDays 天阈值)"
    }

    # ---- 输出审计报告 ----
    $report = [PSCustomObject]@{
        审计时间 = $auditTime
        审计范围 = if ($DomainName) { $DomainName } else { "本地计算机" }
        严重问题数 = $criticalCount
        警告问题数 = $warningCount
        检查项目数 = 3
        密码策略 = $policy
        到期证书 = $expiringCerts
        详细发现 = $findings
    }

    Write-Host "`n=== 安全基线审计结果 ===" -ForegroundColor Green
    Write-Host "  严重问题: $criticalCount 个" -ForegroundColor Red
    Write-Host "  警告问题: $warningCount 个" -ForegroundColor Yellow
    Write-Host "  详细发现:" -ForegroundColor Cyan
    $findings | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

    return $report
}

# 执行新年安全基线审计
$auditReport = Invoke-NewYearSecurityAudit -CertWarningDays 90
```

执行结果示例：

```
[1/3] 正在检查密码策略...
[2/3] 正在检查服务账户状态...
[3/3] 正在扫描证书到期时间...

=== 安全基线审计结果 ===
  严重问题: 1 个
  警告问题: 4 个
  详细发现:
    [严重] 密码最小长度为 8 位，建议至少 12 位
    [信息] 发现 6 个设置了'密码永不过期'的账户
    [警告] 服务账户 svc-backup 密码已 412 天未更新 (密码永不过期)
    [警告] 服务账户 svc-monitor 密码已 289 天未更新 (密码永不过期)
    [证书] 发现 3 个需要关注的证书:
      - [即将过期] CN=api.company.com (剩余 18 天, 到期 2026-01-20)
      - [即将到期] CN=vpn.company.com (剩余 67 天, 到期 2026-03-10)
      - [即将到期] CN=mail.company.com (剩余 82 天, 到期 2026-03-25)
```

审计脚本对三种安全维度进行了分级的合规性检查：密码策略关注长度和轮换周期，服务账户检查是否存在长期未更新密码的"密码永不过期"账户，证书扫描则按剩余天数标记严重程度。每项检查都有 try-catch 保护，即使某项检查因权限不足而失败，也不会影响其他检查继续执行。

## 全年计划任务部署

安全基线审计完成后，下一步是为全年部署按月编排的计划任务。下面的脚本会创建 12 个月的定时维护任务、部署监控脚本、并验证所有任务的健康状态。

```powershell
function Deploy-YearlyScheduledTasks {
    <#
    .SYNOPSIS
    部署全年按月编排的计划任务，并验证任务健康状态
    .PARAMETER Year
    目标年份
    .PARAMETER TaskPrefix
    计划任务名称前缀
    .PARAMETER ScriptBasePath
    维护脚本所在目录
    #>
    param(
        [int]$Year = (Get-Date).Year,
        [string]$TaskPrefix = "IT-Maintenance",
        [string]$ScriptBasePath = "C:\Scripts\Maintenance"
    )

    $deployedTasks = @()
    $failedTasks = @()

    # ---- 1. 定义月度维护任务清单 ----
    $monthlyTasks = @(
        @{
            Name = "SecurityAudit"
            Script = "Invoke-SecurityAudit.ps1"
            Description = "月度安全基线审计"
            DayOfMonth = 1
            Hour = 2
        }
        @{
            Name = "DiskCleanup"
            Script = "Invoke-DiskCleanup.ps1"
            Description = "磁盘空间清理与报告"
            DayOfMonth = 5
            Hour = 3
        }
        @{
            Name = "BackupVerification"
            Script = "Test-BackupIntegrity.ps1"
            Description = "备份完整性验证"
            DayOfMonth = 10
            Hour = 1
        }
        @{
            Name = "CertificateCheck"
            Script = "Get-CertificateExpiry.ps1"
            Description = "证书到期巡检"
            DayOfMonth = 15
            Hour = 2
        }
        @{
            Name = "PatchCompliance"
            Script = "Get-PatchStatus.ps1"
            Description = "补丁合规性检查"
            DayOfMonth = 20
            Hour = 3
        }
        @{
            Name = "PerformanceReport"
            Script = "New-PerformanceReport.ps1"
            Description = "月度性能报告生成"
            DayOfMonth = 25
            Hour = 4
        }
    )

    # ---- 2. 为每月创建计划任务 ----
    Write-Host "`n正在部署 $Year 年度计划任务..." -ForegroundColor Cyan

    foreach ($month in 1..12) {
        foreach ($taskDef in $monthlyTasks) {
            $taskName = "$TaskPrefix-$Year-$($month.ToString('D2'))-$($taskDef.Name)"

            # 计算触发日期（处理月末日期越界）
            $daysInMonth = [DateTime]::DaysInMonth($Year, $month)
            $triggerDay = [math]::Min($taskDef.DayOfMonth, $daysInMonth)
            $triggerDate = Get-Date -Year $Year -Month $month -Day $triggerDay `
                -Hour $taskDef.Hour -Minute 0 -Second 0

            # 如果触发日期已过，跳过创建
            if ($triggerDate -lt (Get-Date)) {
                continue
            }

            $scriptPath = Join-Path $ScriptBasePath $taskDef.Script

            try {
                # 检查是否已存在同名任务
                $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                if ($existingTask) {
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                }

                # 创建计划任务
                $action = New-ScheduledTaskAction `
                    -Execute "powershell.exe" `
                    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Month $month -Year $Year"

                $trigger = New-ScheduledTaskTrigger -Once -At $triggerDate

                $settings = New-ScheduledTaskSettingsSet `
                    -StartWhenAvailable `
                    -DontStopIfGoingOnBatteries `
                    -AllowStartIfOnBatteries `
                    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

                $principal = New-ScheduledTaskPrincipal `
                    -UserId "SYSTEM" `
                    -LogonType ServiceAccount `
                    -RunLevel Highest

                $task = Register-ScheduledTask `
                    -TaskName $taskName `
                    -Action $action `
                    -Trigger $trigger `
                    -Settings $settings `
                    -Principal $principal `
                    -Description "$($taskDef.Description) - $Year 年 $month 月" `
                    -Force

                $deployedTasks += [PSCustomObject]@{
                    任务名称 = $taskName
                    触发时间 = $triggerDate.ToString("yyyy-MM-dd HH:mm")
                    脚本 = $taskDef.Script
                    状态 = "已注册"
                }
            } catch {
                $failedTasks += [PSCustomObject]@{
                    任务名称 = $taskName
                    错误信息 = $_.Exception.Message
                }
            }
        }
    }

    # ---- 3. 部署持续监控任务（每天检查任务健康状态） ----
    $monitorScript = Join-Path $ScriptBasePath "Watch-TaskHealth.ps1"
    $monitorTaskName = "$TaskPrefix-HealthMonitor"

    try {
        $existingMonitor = Get-ScheduledTask -TaskName $monitorTaskName -ErrorAction SilentlyContinue
        if ($existingMonitor) {
            Unregister-ScheduledTask -TaskName $monitorTaskName -Confirm:$false
        }

        $monitorAction = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$monitorScript`""

        $monitorTrigger = New-ScheduledTaskTrigger -Daily -At "06:00"

        $monitorSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

        Register-ScheduledTask `
            -TaskName $monitorTaskName `
            -Action $monitorAction `
            -Trigger $monitorTrigger `
            -Settings $monitorSettings `
            -Principal (New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest) `
            -Description "每日 06:00 检查所有维护任务的健康状态" `
            -Force | Out-Null

        Write-Host "  健康监控任务已部署: $monitorTaskName (每日 06:00)" -ForegroundColor Green
    } catch {
        $failedTasks += [PSCustomObject]@{
            任务名称 = $monitorTaskName
            错误信息 = "健康监控部署失败: $($_.Exception.Message)"
        }
    }

    # ---- 4. 输出部署统计 ----
    Write-Host "`n=== 年度计划任务部署完成 ===" -ForegroundColor Green
    Write-Host "  成功部署: $($deployedTasks.Count) 个" -ForegroundColor Green
    Write-Host "  部署失败: $($failedTasks.Count) 个" -ForegroundColor $(if ($failedTasks.Count -gt 0) { "Red" } else { "Green" })
    Write-Host "`n  前 5 个已部署任务:" -ForegroundColor Cyan
    $deployedTasks | Select-Object -First 5 | Format-Table -AutoSize

    if ($failedTasks.Count -gt 0) {
        Write-Host "  失败任务:" -ForegroundColor Red
        $failedTasks | Format-Table -AutoSize
    }

    return [PSCustomObject]@{
        年份 = $Year
        部署时间 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        成功数 = $deployedTasks.Count
        失败数 = $failedTasks.Count
        已部署任务 = $deployedTasks
        失败任务 = $failedTasks
    }
}

# 部署 2026 年全年计划任务
$deployResult = Deploy-YearlyScheduledTasks -Year 2026
```

执行结果示例：

```
正在部署 2026 年度计划任务...
  健康监控任务已部署: IT-Maintenance-HealthMonitor (每日 06:00)

=== 年度计划任务部署完成 ===
  成功部署: 66 个
  部署失败: 0 个

  前 5 个已部署任务:

任务名称                                    触发时间           脚本                          状态
--------                                    --------           ----                          ----
IT-Maintenance-2026-01-SecurityAudit        2026-01-01 02:00   Invoke-SecurityAudit.ps1      已注册
IT-Maintenance-2026-01-DiskCleanup          2026-01-05 03:00   Invoke-DiskCleanup.ps1        已注册
IT-Maintenance-2026-01-BackupVerification   2026-01-10 01:00   Test-BackupIntegrity.ps1      已注册
IT-Maintenance-2026-01-CertificateCheck     2026-01-15 02:00   Get-CertificateExpiry.ps1     已注册
IT-Maintenance-2026-01-PatchCompliance      2026-01-20 03:00   Get-PatchStatus.ps1           已注册
```

脚本为每个月创建 6 类维护任务，共计 72 个计划任务（实际部署时已过去的月份会被自动跳过）。每个任务使用 SYSTEM 账户以最高权限运行，避免了凭据过期的风险。额外的健康监控任务每天早上 6 点自动检查所有维护任务的状态，发现异常时及时告警。

## 注意事项

1. **权限要求**：年度初始化脚本涉及文件系统操作、计划任务注册和安全策略读取，需要以管理员权限运行。建议在提升权限的 PowerShell 控制台中执行，或者通过"以管理员身份运行"的计划任务自动调用。

2. **备份优先**：在执行目录创建、配置重置和版权更新之前，务必先备份原有的配置文件和脚本。特别是 JSON 配置文件的重置操作不可逆，重置前的累计数据一旦清零就无法恢复。可以在脚本开头加入自动备份逻辑，将原始文件复制到带时间戳的备份目录中。

3. **计划任务的脚本路径**：部署计划任务时，脚本路径必须使用绝对路径。如果维护脚本存放在网络共享上，需要使用 UNC 路径（如 `\\server\share\scripts\`），并确保 SYSTEM 账户对该共享有读取和执行权限。

4. **证书告警阈值**：证书到期扫描的默认告警阈值是 90 天，这个值应根据组织的证书更新流程周期来调整。如果证书更新需要走审批流程，建议将阈值设为 120 天甚至更长，留出足够的时间缓冲。

5. **跨平台兼容性**：安全基线审计中的 Active Directory 相关命令（`Get-ADDefaultDomainPasswordPolicy`、`Get-ADUser`）需要安装 ActiveDirectory PowerShell 模块。如果在不带域控的环境中运行，脚本会回退到本地安全策略检查模式，通过 `secedit` 导出配置进行分析。

6. **任务冲突检测**：如果服务器上已有其他计划任务在同一时间段运行，新部署的维护任务可能会产生资源竞争。建议在部署前先用 `Get-ScheduledTask` 检查目标时段是否已有任务，必要时错开执行时间，避免 CPU、磁盘 I/O 或网络带宽争用。
