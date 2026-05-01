---
layout: post
date: 2025-08-08 08:00:00
title: "PowerShell 技能连载 - 会话录制与审计追踪"
description: PowerTip of the Day - Session Recording and Audit Trail in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- transcript
- audit
- security
- logging
- session-recording
---

_适用于 PowerShell 5.1 及以上版本_

在企业安全合规中，"谁在什么时候执行了什么操作"是最基本也最重要的审计需求。无论是金融行业的操作审计、医疗行业的 HIPAA 合规，还是日常运维的事故排查，完整的操作记录都不可或缺。PowerShell 内置的 `Start-Transcript` 可以记录整个会话的输入输出，结合脚本日志（Script Block Logging）和模块日志（Module Logging），可以构建完整的审计追踪体系。

本文将讲解 PowerShell 会话录制的多种方式，以及如何构建满足安全合规要求的审计系统。

## Start-Transcript 基础录制

```powershell
# Start-Transcript 记录会话中的所有输入和输出

function Start-SessionRecording {
    param(
        [string]$LogRoot = "C:\Logs\PowerShell\Transcripts",

        [string]$SessionName = "Interactive"
    )

    # 确保日志目录存在
    $datePath = Join-Path $LogRoot (Get-Date -Format "yyyy\\MM")
    New-Item -Path $datePath -ItemType Directory -Force | Out-Null

    # 生成唯一文件名：日期_主机_用户_会话ID
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $computer = $env:COMPUTERNAME
    $user = $env:USERNAME
    $sessionId = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $fileName = "${timestamp}_${computer}_${user}_${sessionId}.txt"

    $transcriptPath = Join-Path $datePath $fileName

    # 启动录制
    Start-Transcript -Path $transcriptPath -IncludeInvocationHeader -Force | Out-Null

    # 在录制文件中写入元数据标记
    Write-Host "========================================"
    Write-Host "会话录制已启动"
    Write-Host "  会话类型：$SessionName"
    Write-Host "  操作人员：$user"
    Write-Host "  计算机名：$computer"
    Write-Host "  进程 ID：$sessionId"
    Write-Host "  开始时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "  录制文件：$transcriptPath"
    Write-Host "========================================"

    return $transcriptPath
}

function Stop-SessionRecording {
    param(
        [string]$Reason = "正常结束"
    )

    Write-Host "========================================"
    Write-Host "会话录制即将停止"
    Write-Host "  结束原因：$Reason"
    Write-Host "  结束时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "========================================"

    Stop-Transcript | Out-Null
    Write-Host "录制已停止并保存" -ForegroundColor Green
}

# 使用示例
$transcriptFile = Start-SessionRecording -SessionName "Maintenance"
```

执行结果示例：

```
**************************************
Windows PowerShell transcript start
Start time: 20250808083000
Username: CONTOSO\Admin
RunAs User: CONTOSO\Admin
Machine: SRV-WEB01 (Microsoft Windows NT 10.0.20348.0)
========================================
会话录制已启动
  会话类型：Maintenance
  操作人员：Admin
  计算机名：SRV-WEB01
  进程 ID：12345
  开始时间：2025-08-08 08:30:00
  录制文件：C:\Logs\PowerShell\Transcripts\2025\08\20250808_083000_SRV-WEB01_Admin_12345.txt
========================================
```

## 脚本内嵌录制

```powershell
# 在脚本中自动启用录制，确保运维操作可追溯

function Invoke-WithAuditTrail {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [string]$OperationName = "UnnamedOperation",

        [string]$LogRoot = "C:\Logs\PowerShell\Audit",

        [hashtable]$Metadata
    )

    # 构建审计日志路径
    $datePath = Join-Path $LogRoot (Get-Date -Format "yyyy\\MM\\dd")
    New-Item -Path $datePath -ItemType Directory -Force | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $transcriptPath = Join-Path $datePath "${timestamp}_${OperationName}.log"

    # 记录审计元数据
    $auditHeader = @(
        "=== 审计记录 ==="
        "  操作名称：$OperationName"
        "  执行用户：$env:USERNAME"
        "  计算机名：$env:COMPUTERNAME"
        "  开始时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )

    if ($Metadata) {
        $auditHeader += "  --- 自定义元数据 ---"
        foreach ($key in $Metadata.Keys) {
            $auditHeader += "  ${key}: $($Metadata[$key])"
        }
    }

    # 启动录制
    Start-Transcript -Path $transcriptPath -Force | Out-Null
    $auditHeader | ForEach-Object { Write-Host $_ }

    $success = $false
    $errorMessage = ""
    $startTime = Get-Date

    try {
        # 执行目标脚本
        $result = & $ScriptBlock
        $success = $true
        Write-Host "=== 操作完成 ==="
        Write-Host "  结果：成功"
    } catch {
        $success = $false
        $errorMessage = $_.Exception.Message
        Write-Host "=== 操作失败 ===" -ForegroundColor Red
        Write-Host "  错误信息：$errorMessage" -ForegroundColor Red
    } finally {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).ToString("hh\:mm\:ss")

        Write-Host "  耗时：$duration"
        Write-Host "  结束时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Stop-Transcript | Out-Null
    }

    # 返回审计摘要
    return [PSCustomObject]@{
        Operation   = $OperationName
        Transcript  = $transcriptPath
        Success     = $success
        Error       = $errorMessage
        StartTime   = $startTime
        EndTime     = $endTime
        Duration    = $duration
    }
}

# 使用示例
$auditResult = Invoke-WithAuditTrail -OperationName "Deploy-MyApp" -Metadata @{
    Version   = "2.5.0"
    Env       = "Production"
    Approver  = "Manager Zhang"
    Ticket    = "OPS-2025-0808"
} -ScriptBlock {
    Write-Host "开始部署 MyApp v2.5.0..."
    Start-Sleep -Seconds 2
    Write-Host "复制文件到目标目录..."
    Write-Host "重启服务..."
    Write-Host "验证服务状态..."
    "DeployComplete"
}

$auditResult | Format-List
```

执行结果示例：

```
=== 审计记录 ===
  操作名称：Deploy-MyApp
  执行用户：Admin
  计算机名：SRV-WEB01
  开始时间：2025-08-08 08:30:00
  --- 自定义元数据 ---
  Version: 2.5.0
  Env: Production
  Approver: Manager Zhang
  Ticket: OPS-2025-0808
开始部署 MyApp v2.5.0...
复制文件到目标目录...
重启服务...
验证服务状态...
=== 操作完成 ===
  结果：成功
  耗时：00:00:02
  结束时间：2025-08-08 08:30:02

Operation   : Deploy-MyApp
Transcript  : C:\Logs\PowerShell\Audit\2025\08\08\20250808_083000_Deploy-MyApp.log
Success     : True
Error       :
StartTime   : 2025-08-08 08:30:00
EndTime     : 2025-08-08 08:30:02
Duration    : 00:00:02
```

## Script Block Logging 集成

```powershell
# 读取 Windows 事件日志中的 PowerShell 脚本块日志
# 需要提前启用 Script Block Logging（组策略或注册表）

function Enable-ScriptBlockLogging {
    param(
        [switch]$IncludeWarningLevel
    )

    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # 启用脚本块日志
    Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1

    if ($IncludeWarningLevel) {
        # 同时记录警告级别（如混淆代码、可疑命令）
        Set-ItemProperty -Path $regPath -Name "EnableScriptBlockInvocationLogging" -Value 1
    }

    Write-Host "Script Block Logging 已启用" -ForegroundColor Green
}

function Get-ScriptBlockLog {
    param(
        [int]$MaxEvents = 50,

        [datetime]$StartTime,

        [string]$OutputPath
    )

    $params = @{
        LogName   = "Microsoft-Windows-PowerShell/Operational"
        Id        = 4104
        MaxEvents = $MaxEvents
    }

    if ($StartTime) {
        $params["StartTime"] = $StartTime
    }

    $events = Get-WinEvent @params -ErrorAction SilentlyContinue

    if (-not $events) {
        Write-Warning "未找到脚本块日志"
        return
    }

    $logEntries = foreach ($event in $events) {
        [PSCustomObject]@{
            TimeCreated = $event.TimeCreated
            Level       = $event.LevelDisplayName
            Computer    = $event.MachineName
            UserId      = $event.UserId
            ScriptBlock = $event.Properties[0].Value.Substring(
                0, [Math]::Min(200, $event.Properties[0].Value.Length)
            )
            Path        = if ($event.Properties.Count -gt 1) {
                $event.Properties[1].Value
            } else {
                "Interactive"
            }
        }
    }

    if ($OutputPath) {
        $logEntries | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "已导出 $($logEntries.Count) 条日志到：$OutputPath" -ForegroundColor Green
    }

    return $logEntries
}

# 启用脚本块日志
Enable-ScriptBlockLogging -IncludeWarningLevel

# 查询最近的脚本块日志
Get-ScriptBlockLog -MaxEvents 10 -StartTime (Get-Date).AddHours(-1) |
    Format-Table TimeCreated, Level, Path -AutoSize
```

执行结果示例：

```
Script Block Logging 已启用

TimeCreated          Level        Path
-----------          -----        ----
2025-08-08 08:28:15  Information  Interactive
2025-08-08 08:28:14  Information  Interactive
2025-08-08 08:25:30  Warning      C:\Scripts\deploy.ps1
2025-08-08 08:25:29  Information  C:\Scripts\deploy.ps1
```

## 审计日志搜索与分析

```powershell
# 审计日志分析工具：从 Transcript 文件中搜索敏感操作

function Search-AuditLog {
    param(
        [Parameter(Mandatory)]
        [string]$LogRoot,

        [string[]]$Keywords = @("Remove-", "Stop-", "Delete", "Drop", "Format"),

        [datetime]$StartDate,

        [datetime]$EndDate,

        [string]$UserFilter,

        [int]$ContextLines = 3
    )

    # 查找所有 transcript 文件
    $files = Get-ChildItem -Path $LogRoot -Recurse -Filter "*.txt" -File

    if ($StartDate) {
        $files = $files | Where-Object { $_.LastWriteTime -ge $StartDate }
    }
    if ($EndDate) {
        $files = $files | Where-Object { $_.LastWriteTime -le $EndDate }
    }

    Write-Host "扫描 $($files.Count) 个审计日志文件..." -ForegroundColor Cyan

    $findings = @()
    $pattern = ($Keywords | ForEach-Object { [regex]::Escape($_) }) -join "|"

    foreach ($file in $files) {
        $lines = Get-Content $file.FullName -Encoding UTF8

        # 提取用户信息
        $userLine = $lines | Where-Object { $_ -match "^Username:" } | Select-Object -First 1
        $fileUser = if ($userLine -match "Username:\s*(.+)") {
            $Matches[1].Trim()
        } else {
            "Unknown"
        }

        # 用户过滤
        if ($UserFilter -and $fileUser -notlike "*$UserFilter*") {
            continue
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $pattern) {
                # 收集上下文行
                $start = [Math]::Max(0, $i - $ContextLines)
                $end = [Math]::Min($lines.Count - 1, $i + $ContextLines)
                $context = ($lines[$start..$end] | Where-Object { $_ }) -join "`n"

                $findings += [PSCustomObject]@{
                    File      = $file.FullName
                    User      = $fileUser
                    LineNum   = $i + 1
                    Match     = $lines[$i].Trim()
                    Context   = $context
                    Timestamp = $file.LastWriteTime
                }
            }
        }
    }

    Write-Host "发现 $($findings.Count) 条敏感操作记录" `
        -ForegroundColor $(if ($findings.Count -gt 0) { "Yellow" } else { "Green" })

    return $findings
}

# 生成审计摘要报告
function New-AuditSummaryReport {
    param(
        [Parameter(Mandatory)]
        [object[]]$Findings,

        [string]$OutputPath = "C:\Reports\AuditSummary.html"
    )

    $reportDir = Split-Path $OutputPath -Parent
    New-Item $reportDir -ItemType Directory -Force | Out-Null

    $byUser = $Findings | Group-Object -Property User | Sort-Object Count -Descending
    $byKeyword = foreach ($f in $Findings) {
        foreach ($kw in @("Remove-", "Stop-", "Delete", "Drop")) {
            if ($f.Match -match [regex]::Escape($kw)) {
                [PSCustomObject]@{ Keyword = $kw; Match = $f.Match }
            }
        }
    } | Group-Object -Property Keyword | Sort-Object Count -Descending

    $html = @"
<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>审计摘要报告</title>
<style>
body{font-family:'Segoe UI',sans-serif;margin:20px;background:#f5f6fa}
h1{color:#2d3436;border-bottom:2px solid #e74c3c}
h2{color:#2d3436;margin-top:30px}
table{width:100%;border-collapse:collapse;margin:10px 0}
th{background:#0984e3;color:white;padding:10px;text-align:left}
td{padding:8px 10px;border-bottom:1px solid #dfe6e9}
.summary{display:flex;gap:15px;margin:15px 0}
.card{background:white;border-radius:8px;padding:15px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.card .value{font-size:24px;font-weight:bold}
</style></head><body>
<h1>审计摘要报告</h1>
<p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<div class="summary">
<div class="card"><div class="value" style="color:#e74c3c">$($Findings.Count)</div><div>敏感操作总数</div></div>
<div class="card"><div class="value" style="color:#0984e3">$($byUser.Count)</div><div>涉及用户</div></div>
</div>
<h2>按用户统计</h2><table><tr><th>用户</th><th>操作次数</th></tr>
$($byUser | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" })
</table>
<h2>按操作类型统计</h2><table><tr><th>关键字</th><th>次数</th></tr>
$($byKeyword | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Count)</td></tr>" })
</table></body></html>
"@

    $html | Set-Content $OutputPath -Encoding UTF8
    Write-Host "审计报告已生成：$OutputPath" -ForegroundColor Green
}

# 使用示例
$results = Search-AuditLog -LogRoot "C:\Logs\PowerShell\Transcripts" `
    -Keywords @("Remove-", "Stop-", "Delete") `
    -StartDate (Get-Date).AddDays(-7)

if ($results) {
    New-AuditSummaryReport -Findings $results
}
```

执行结果示例：

```
扫描 42 个审计日志文件...
发现 15 条敏感操作记录

审计报告已生成：C:\Reports\AuditSummary.html
```

## 全局自动录制配置

```powershell
# 通过 Profile 配置所有 PowerShell 会话自动录制

$profileContent = @'
# ===== 全局审计录制 =====
$transcriptRoot = "C:\Logs\PowerShell\Transcripts"
$dateFolder = Join-Path $transcriptRoot (Get-Date -Format "yyyy\\MM")
New-Item -Path $dateFolder -ItemType Directory -Force | Out-Null

$sessionId = [System.Diagnostics.Process]::GetCurrentProcess().Id
$transcriptFile = Join-Path $dateFolder "$(Get-Date -Format 'yyyyMMdd_HHmmss')_${env:COMPUTERNAME}_${env:USERNAME}_${sessionId}.txt"

try {
    Start-Transcript -Path $transcriptFile -IncludeInvocationHeader -Force | Out-Null
} catch {
    # 录制启动失败不阻止正常工作
    Write-Debug "Transcript 启动失败：$($_.Exception.Message)"
}

# 注册会话退出事件，确保录制正常结束
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    try {
        Stop-Transcript | Out-Null
    } catch {
        # 忽略退出时的错误
    }
}
'@

# 显示配置说明
function Set-GlobalTranscript {
    param(
        [string]$ProfilePath = $PROFILE.AllUsersAllHosts
    )

    Write-Host "将以下内容添加到 PowerShell Profile：" -ForegroundColor Cyan
    Write-Host "  路径：$ProfilePath" -ForegroundColor Yellow
    Write-Host ""

    if (Test-Path $ProfilePath) {
        $existing = Get-Content $ProfilePath -Raw -Encoding UTF8
        if ($existing -match "Start-Transcript") {
            Write-Warning "Profile 中已存在 Start-Transcript 配置，跳过"
            return
        }

        # 追加到已有 Profile
        $profileContent | Add-Content $ProfilePath -Encoding UTF8
        Write-Host "已追加到现有 Profile" -ForegroundColor Green
    } else {
        $profileDir = Split-Path $ProfilePath -Parent
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        $profileContent | Set-Content $ProfilePath -Encoding UTF8
        Write-Host "已创建新 Profile" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "新会话将自动启动录制。" -ForegroundColor Green
    Write-Host "注意：所有用户的所有 PowerShell 会话都将被录制。" -ForegroundColor Yellow
}

# 检查当前录制状态
function Get-TranscriptStatus {
    $transcript = try { Get-Transcript } catch { $null }

    if ($transcript) {
        [PSCustomObject]@{
            IsRecording = $true
            Path        = $transcript.Path
            StartTime   = $transcript.StartTime
            SizeKB      = if (Test-Path $transcript.Path) {
                [Math]::Round((Get-Item $transcript.Path).Length / 1KB, 1)
            } else { "N/A" }
        }
    } else {
        [PSCustomObject]@{
            IsRecording = $false
            Path        = "N/A"
            StartTime   = "N/A"
            SizeKB      = "N/A"
        }
    }
}

Get-TranscriptStatus | Format-List
```

执行结果示例：

```
将以下内容添加到 PowerShell Profile：
  路径：C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
已创建新 Profile

新会话将自动启动录制。
注意：所有用户的所有 PowerShell 会话都将被录制。

IsRecording : True
Path        : C:\Logs\PowerShell\Transcripts\2025\08\20250808_083000_SRV-WEB01_Admin_12345.txt
StartTime   : 2025-08-08 08:30:00
SizeKB      : 12.5
```

## 注意事项

1. **存储空间**：Transcript 文件会持续增长，务必配置定期清理策略（如保留 90 天），避免磁盘被填满
2. **敏感信息**：录制会捕获密码输入等敏感内容，生产环境中应在密码提示前暂停录制或使用 `Read-Host -AsSecureString`
3. **性能影响**：Script Block Logging 在高频脚本环境中可能产生大量事件日志，建议仅在高安全要求的服务器上启用
4. **日志完整性**：有权限的用户可以执行 `Stop-Transcript` 停止录制，关键系统应结合 Windows 事件转发（WEF）集中收集日志
5. **合规要求**：不同行业对日志保留期限有不同要求（如金融行业通常 7 年），需根据实际合规标准配置保留策略
6. **编码一致性**：Transcript 文件使用系统默认编码，在跨语言环境中读取时可能出现乱码，分析工具应指定正确的编码
