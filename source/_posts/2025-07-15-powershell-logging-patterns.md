---
layout: post
date: 2025-07-15 08:00:00
updated: 2025-07-15 08:00:00
title: "PowerShell 技能连载 - 日志记录模式"
description: PowerTip of the Day - Logging Patterns in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- logging
- structured-logging
- monitoring
---

_适用于 PowerShell 5.1 及以上版本_

生产级脚本必须有可靠的日志记录——没有日志的脚本就像黑盒，出了问题无从排查。但"加个 `Write-Host`"和"设计一个日志系统"之间差距巨大。好的日志系统应该支持多级别输出、同时写文件和控制台、自动轮转、结构化格式，而且不影响脚本性能。

本文将讲解 PowerShell 中的日志记录模式，从简单到复杂，适用于不同规模的脚本和自动化场景。

## 简单日志函数

```powershell
# 基础日志函数
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]$Level = "INFO",

        [string]$LogPath = "C:\Logs\script.log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $entry = "[$timestamp] [$Level] $Message"

    # 控制台输出（带颜色）
    $color = switch ($Level) {
        "DEBUG" { "DarkGray" }
        "INFO"  { "White" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "FATAL" { "Magenta" }
    }
    Write-Host $entry -ForegroundColor $color

    # 文件输出
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogPath -Value $entry -Encoding UTF8
}

# 使用示例
Write-Log -Level INFO  "开始部署 MyApp v2.5.0"
Write-Log -Level DEBUG "读取配置文件：C:\MyApp\config.json"
Write-Log -Level WARN  "磁盘空间低于 20%"
Write-Log -Level ERROR "数据库连接超时（30s）"
Write-Log -Level FATAL "服务启动失败，中止部署"
```

执行结果示例：

```
[2025-07-15 08:30:15.123] [INFO] 开始部署 MyApp v2.5.0
[2025-07-15 08:30:15.125] [DEBUG] 读取配置文件：C:\MyApp\config.json
[2025-07-15 08:30:15.130] [WARN] 磁盘空间低于 20%
[2025-07-15 08:30:15.135] [ERROR] 数据库连接超时（30s）
[2025-07-15 08:30:15.140] [FATAL] 服务启动失败，中止部署
```

## 可配置日志系统

```powershell
function New-Logger {
    <#
    .SYNOPSIS
    创建可配置的日志记录器
    #>
    param(
        [string]$Name = "Script",

        [string]$LogDirectory = "C:\Logs",

        [ValidateSet("DEBUG", "INFO", "WARN", "ERROR")]
        [string]$MinLevel = "INFO",

        [switch]$LogToConsole,

        [switch]$LogToFile,

        [int]$MaxFileSizeMB = 10,

        [int]$MaxFiles = 5
    )

    $logPath = Join-Path $LogDirectory "$Name-$(Get-Date -Format 'yyyyMMdd').log"

    return [PSCustomObject]@{
        Name         = $Name
        LogPath      = $logPath
        MinLevel     = $MinLevel
        LogToConsole = $LogToConsole
        LogToFile    = $LogToFile
        MaxFileSizeMB = $MaxFileSizeMB
        MaxFiles     = $MaxFiles
    } | Add-Member -MemberType ScriptMethod -Name Write -Value {
        param($Message, $Level = "INFO")

        $levelOrder = @{ DEBUG = 0; INFO = 1; WARN = 2; ERROR = 3 }
        if ($levelOrder[$Level] -lt $levelOrder[$this.MinLevel]) { return }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $entry = "[$timestamp] [$Level] [$($this.Name)] $Message"

        if ($this.LogToConsole) {
            $color = switch ($Level) {
                "DEBUG" { "DarkGray" }
                "INFO"  { "Cyan" }
                "WARN"  { "Yellow" }
                "ERROR" { "Red" }
            }
            Write-Host $entry -ForegroundColor $color
        }

        if ($this.LogToFile) {
            # 日志轮转检查
            if (Test-Path $this.LogPath) {
                $size = (Get-Item $this.LogPath).Length / 1MB
                if ($size -ge $this.MaxFileSizeMB) {
                    $baseName = $this.LogPath -replace '\.log$', ''
                    for ($i = $this.MaxFiles - 1; $i -ge 1; $i--) {
                        $old = "$baseName.$i.log"
                        if (Test-Path $old) {
                            if ($i -eq $this.MaxFiles - 1) {
                                Remove-Item $old -Force
                            } else {
                                Move-Item $old "$baseName.$($i+1).log" -Force
                            }
                        }
                    }
                    Move-Item $this.LogPath "$baseName.1.log" -Force
                }
            }

            $logDir = Split-Path $this.LogPath -Parent
            if (-not (Test-Path $logDir)) {
                New-Item $logDir -ItemType Directory -Force | Out-Null
            }
            Add-Content -Path $this.LogPath -Value $entry -Encoding UTF8
        }
    } -Force -PassThru
}

# 创建日志记录器
$log = New-Logger -Name "Deploy" -LogDirectory "C:\Logs\Deploy" `
    -LogToConsole -LogToFile -MinLevel DEBUG

$log.Write("部署开始", "INFO")
$log.Write("备份旧版本", "DEBUG")
$log.Write("停止服务", "INFO")
$log.Write("复制文件", "INFO")
$log.Write("磁盘空间不足", "WARN")
$log.Write("服务启动失败", "ERROR")
$log.Write("部署完成", "INFO")
```

执行结果示例：

```
[2025-07-15 08:30:15.123] [INFO] [Deploy] 部署开始
[2025-07-15 08:30:15.125] [DEBUG] [Deploy] 备份旧版本
[2025-07-15 08:30:15.130] [INFO] [Deploy] 停止服务
[2025-07-15 08:30:15.135] [INFO] [Deploy] 复制文件
[2025-07-15 08:30:15.140] [WARN] [Deploy] 磁盘空间不足
[2025-07-15 08:30:15.145] [ERROR] [Deploy] 服务启动失败
[2025-07-15 08:30:15.150] [INFO] [Deploy] 部署完成
```

## 结构化日志

```powershell
# JSON 结构化日志（适合 ELK/Splunk 等日志平台）
function Write-StructuredLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [hashtable]$Properties = @{},
        [string]$LogPath = "C:\Logs\structured.json"
    )

    $entry = [ordered]@{
        timestamp   = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        level       = $Level
        message     = $Message
        script      = $MyInvocation.ScriptName
        line        = $MyInvocation.ScriptLineNumber
        computer    = $env:COMPUTERNAME
        user        = $env:USERNAME
    }

    # 合并额外属性
    foreach ($key in $Properties.Keys) {
        $entry[$key] = $Properties[$key]
    }

    $jsonLine = $entry | ConvertTo-Json -Compress
    Add-Content -Path $LogPath -Value $jsonLine -Encoding UTF8
}

# 使用结构化日志
Write-StructuredLog -Message "服务健康检查" -Level "INFO" -Properties @{
    service     = "MyApp"
    action      = "health_check"
    duration_ms = 45
    status      = "healthy"
}

Write-StructuredLog -Message "部署完成" -Level "INFO" -Properties @{
    app_name    = "MyApp"
    version     = "2.5.0"
    environment = "production"
    duration_s  = 120
    steps       = @("backup", "deploy", "verify")
    server      = "SRV01"
}

Write-StructuredLog -Message "连接超时" -Level "ERROR" -Properties @{
    server      = "db-prod-01"
    port        = 5432
    timeout_s   = 30
    retry_count = 3
    error_code  = "CONN_TIMEOUT"
}

# 读取结构化日志并分析
$logs = Get-Content "C:\Logs\structured.json" | ConvertFrom-Json
$errors = $logs | Where-Object { $_.level -eq "ERROR" }
Write-Host "`n最近错误：$($errors.Count) 条" -ForegroundColor Red
$errors | Select-Object timestamp, message, server | Format-Table -AutoSize
```

执行结果示例：

```
最近错误：1 条
timestamp                    message        server
---------                    -------        ------
2025-07-15T08:30:20.123Z     连接超时       db-prod-01
```

## 日志分析工具

```powershell
# 快速分析日志文件
function Get-LogSummary {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$LastN = 100
    )

    $lines = Get-Content $LogPath -Tail $LastN

    $stats = @{
        Total   = 0
        Info    = 0
        Warning = 0
        Error   = 0
        Debug   = 0
    }

    $errorMessages = @()

    foreach ($line in $lines) {
        $stats.Total++

        if ($line -match '\[INFO\]')  { $stats.Info++ }
        if ($line -match '\[WARN')    { $stats.Warning++ }
        if ($line -match '\[ERROR\]') {
            $stats.Error++
            $errorMessages += $line
        }
        if ($line -match '\[DEBUG\]') { $stats.Debug++ }
    }

    Write-Host "日志摘要（最近 $LastN 行）：" -ForegroundColor Cyan
    Write-Host "  总计：$($stats.Total)"
    Write-Host "  INFO：$($stats.Info)" -ForegroundColor White
    Write-Host "  WARN：$($stats.Warning)" -ForegroundColor Yellow
    Write-Host "  ERROR：$($stats.Error)" -ForegroundColor Red
    Write-Host "  DEBUG：$($stats.Debug)" -ForegroundColor DarkGray

    if ($errorMessages.Count -gt 0) {
        Write-Host "`n最近错误：" -ForegroundColor Red
        $errorMessages | Select-Object -Last 5 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Red
        }
    }
}

Get-LogSummary -LogPath "C:\Logs\Deploy\Deploy-20250715.log" -LastN 500
```

执行结果示例：

```
日志摘要（最近 500 行）：
  总计：500
  INFO：320
  WARN：45
  ERROR：12
  DEBUG：123

最近错误：
  [2025-07-15 08:25:10] [ERROR] [Deploy] 数据库连接超时
  [2025-07-15 08:30:45] [ERROR] [Deploy] 文件复制失败：拒绝访问
  [2025-07-15 08:35:22] [ERROR] [Deploy] 服务启动失败
```

## 注意事项

1. **性能影响**：每次 `Add-Content` 都会打开-写入-关闭文件，高频日志使用 `StreamWriter` 提升性能
2. **并发写入**：多进程同时写同一日志文件会导致内容交错，使用文件锁或独立日志文件
3. **日志轮转**：不限制日志文件大小会耗尽磁盘空间，务必实现轮转或使用日志框架
4. **敏感数据**：日志中不要记录密码、Token、完整连接字符串等敏感信息
5. **日志级别**：DEBUG 详细记录用于开发排查，生产环境设置为 INFO 或 WARN
6. **UTF-8 BOM**：`Add-Content -Encoding UTF8` 在 PowerShell 5.1 中会添加 BOM，使用 `[System.IO.StreamWriter]` 可避免
