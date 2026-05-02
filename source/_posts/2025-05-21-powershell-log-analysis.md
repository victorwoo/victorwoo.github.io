---
layout: post
date: 2025-05-21 08:00:00
updated: 2025-05-21 08:00:00
title: "PowerShell 技能连载 - 日志分析与解析"
description: PowerTip of the Day - Log Analysis and Parsing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- logging
- log-analysis
- text-parsing
---

_适用于 PowerShell 5.1 及以上版本_

日志分析是运维排障的核心技能。无论是 IIS 访问日志、应用程序错误日志、Windows 事件日志还是自定义的业务日志，快速定位问题需要高效的日志解析能力。PowerShell 的文本处理命令（`Select-String`、`ConvertFrom-Csv`、正则表达式）结合对象管道，可以构建强大的日志分析工具链。

本文将讲解常见的日志格式解析方法、模式匹配技巧，以及实用的日志分析脚本。

## 基础文本搜索

`Select-String` 是 PowerShell 中的 `grep`，支持正则表达式和文件通配符：

```powershell
# 基础搜索：在日志文件中查找关键词
Select-String -Path "C:\Logs\app.log" -Pattern "ERROR" |
    Select-Object -First 10 |
    ForEach-Object { $_.Line }

# 显示匹配行的上下文（前后各 2 行）
Select-String -Path "C:\Logs\app.log" -Pattern "Exception" -Context 2,2

# 递归搜索目录
Select-String -Path "C:\Logs\*.log" -Pattern "timeout|refused|reset" -Recurse

# 统计各日志文件中的错误数
Get-ChildItem "C:\Logs" -Filter *.log |
    ForEach-Object {
        $errors = (Select-String -Path $_.FullName -Pattern "ERROR|FATAL" -Quiet).Count
        [PSCustomObject]@{
            File    = $_.Name
            Errors  = $errors
            SizeMB  = [math]::Round($_.Length / 1MB, 2)
        }
    } | Sort-Object Errors -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
2025-05-21 08:15:32 ERROR [DB] Connection timeout after 30s
2025-05-21 08:20:18 ERROR [API] Upstream timeout (504) - /api/users
2025-05-21 08:25:45 ERROR [AUTH] Failed to authenticate user: john.doe

File          Errors SizeMB
----          ------ ------
app-2025.log     42  15.32
api-2025.log     28   8.45
auth-2025.log    12   3.21
```

## 解析结构化日志

许多应用使用结构化的日志格式（如 JSON Lines），PowerShell 可以轻松解析：

```powershell
# 解析 JSON Lines 格式的日志
$logEntries = Get-Content "C:\Logs\app.jsonl" |
    ForEach-Object {
        try {
            $_ | ConvertFrom-Json
        } catch {
            $null
        }
    } | Where-Object { $_ }

# 按日志级别过滤
$logEntries | Where-Object { $_.level -eq 'error' } |
    Select-Object timestamp, message, @{N='source'; E={$_.source -join '.'}} |
    Format-Table -AutoSize

# 按时间范围过滤
$startTime = (Get-Date).AddHours(-1)
$recentLogs = $logEntries |
    Where-Object { [datetime]$_.timestamp -gt $startTime }

Write-Host "最近 1 小时日志条数：$($recentLogs.Count)"

# 按字段聚合统计
$logEntries | Group-Object level |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize

# 提取错误日志中的异常类型
$logEntries | Where-Object { $_.level -eq 'error' -and $_.exception } |
    ForEach-Object {
        $exType = if ($_.exception.type) { $_.exception.type } else { $_.exception.Split("`n")[0] }
        [PSCustomObject]@{
            Timestamp     = $_.timestamp
            ExceptionType = $exType
            Message       = $_.message
        }
    } | Format-Table -AutoSize -Wrap
```

执行结果示例：

```
timestamp                  message                     source
---------                  -------                     ------
2025-05-21T08:15:32.123Z   Connection timeout after 30s db.pool
2025-05-21T08:20:18.456Z   Upstream timeout (504)       api.gateway

最近 1 小时日志条数：342

Name     Count
----     -----
info       280
warn        45
error       17

Timestamp               ExceptionType              Message
---------               --------------              -------
2025-05-21T08:15:32Z    SqlException               Connection timeout
2025-05-21T08:22:15Z    HttpRequestException        Upstream timeout
2025-05-21T08:30:01Z    AuthenticationException    Invalid token
```

## 解析 IIS 日志

IIS 日志使用 W3C 扩展格式，是空格分隔的文本。使用 `ConvertFrom-Csv` 可以高效解析：

```powershell
function Get-IISLogEntry {
    <#
    .SYNOPSIS
    解析 IIS W3C 格式日志
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [datetime]$StartTime,
        [datetime]$EndTime
    )

    # 读取文件头获取字段定义
    $header = Get-Content $LogPath |
        Where-Object { $_ -match '^#Fields:' } |
        Select-Object -First 1

    if (-not $header) {
        Write-Error "无法识别的日志格式"
        return
    }

    $fields = ($header -replace '^#Fields:\s*', '') -split '\s+'

    # 解析日志行
    $entries = Get-Content $LogPath |
        Where-Object { $_ -notmatch '^\#' -and $_.Trim() } |
        ConvertFrom-Csv -Delimiter ' ' -Header $fields

    # 时间过滤
    if ($StartTime -or $EndTime) {
        $entries = $entries | Where-Object {
            $ts = [datetime]"$($_.date) $($_.time)"
            ($StartTime -eq $null -or $ts -ge $StartTime) -and
            ($EndTime -eq $null -or $ts -le $EndTime)
        }
    }

    return $entries
}

# 分析 IIS 日志
$iisLogs = Get-IISLogEntry -LogPath "C:\inetpub\logs\LogFiles\W3SVC1\ex250521.log" `
    -StartTime (Get-Date).AddHours(-1)

# 统计 HTTP 状态码分布
$iisLogs | Group-Object 'sc-status' |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize

# 统计访问量 Top 10 URL
$iisLogs | Group-Object 'cs-uri-stem' |
    Sort-Object Count -Descending |
    Select-Object -First 10 Count, Name |
    Format-Table -AutoSize

# 统计慢请求（响应时间 > 5 秒）
$iisLogs | Where-Object { $_.'time-taken' -gt 5000 } |
    Select-Object date, time, 'cs-uri-stem', 'sc-status', 'time-taken' |
    Sort-Object 'time-taken' -Descending |
    Format-Table -AutoSize
```

执行结果示例：

```
Name Count
---- -----
200   8456
304   1234
404    456
500    123

Count Name
----- ----
 2345 /api/users
 1876 /api/products
  987 /static/css/main.css
  654 /api/orders

date       time     cs-uri-stem   sc-status time-taken
----       ----     -----------   ---------- ----------
2025-05-21 08:15:32 /api/search   200        12456
2025-05-21 08:22:18 /api/reports  200         8734
2025-05-21 08:35:45 /api/export   200         6234
```

## 正则表达式提取模式

对于非结构化的文本日志，正则表达式是提取关键信息的利器：

```powershell
# 提取 IP 地址访问统计
$logContent = Get-Content "C:\Logs\access.log" -Tail 10000

$ipPattern = '\b(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\b'
$ips = $logContent | Select-String -Pattern $ipPattern |
    ForEach-Object { $_.Matches.Groups[1].Value }

$ips | Group-Object | Sort-Object Count -Descending |
    Select-Object -First 20 Count, Name |
    Format-Table -AutoSize

# 提取错误日志中的关键信息
$errorPattern = '(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}).*?ERROR.*?\[(\w+)\]\s+(.+)'
$errorEntries = $logContent | Select-String -Pattern $errorPattern |
    ForEach-Object {
        [PSCustomObject]@{
            Timestamp = $_.Matches.Groups[1].Value
            Module    = $_.Matches.Groups[2].Value
            Message   = $_.Matches.Groups[3].Value
        }
    }

$errorEntries | Group-Object Module |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize

# 提取 HTTP 状态码和响应时间
$httpPattern = '"\s(\d{3})\s(\d+)\s(\d+)'
$httpStats = $logContent | Select-String -Pattern $httpPattern |
    ForEach-Object {
        [PSCustomObject]@{
            StatusCode = $_.Matches.Groups[1].Value
            Size       = $_.Matches.Groups[2].Value
            Duration   = $_.Matches.Groups[3].Value
        }
    }

$httpStats | Where-Object { $_.StatusCode -match '^[45]' } |
    Group-Object StatusCode |
    Format-Table Name, Count -AutoSize
```

执行结果示例：

```
Count Name
----- ----
 1245 192.168.1.100
  876 10.0.0.55
  432 172.16.0.10
  234 192.168.1.101

Name     Count
----     -----
DB           15
API          10
AUTH          8
CACHE         4

Name Count
---- -----
500    89
404    45
503    12
```

## 实时日志监控

对于正在运行的服务，实时监控日志输出可以快速发现问题：

```powershell
function Watch-LogFile {
    <#
    .SYNOPSIS
    实时监控日志文件，匹配关键词时输出
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Pattern = @('ERROR', 'FATAL', 'WARN'),

        [int]$MaxLines = 1000
    )

    $patternRegex = $Pattern -join '|'

    Write-Host "监控中：$Path" -ForegroundColor Cyan
    Write-Host "过滤规则：$patternRegex" -ForegroundColor DarkGray
    Write-Host "按 Ctrl+C 停止`n" -ForegroundColor DarkGray

    # 先输出已有的匹配行
    Get-Content $Path -Tail 50 |
        Where-Object { $_ -match $patternRegex } |
        ForEach-Object {
            $level = if ($_ -match 'ERROR|FATAL') { 'Error' } else { 'Warning' }
            $color = if ($level -eq 'Error') { 'Red' } else { 'Yellow' }
            Write-Host $_ -ForegroundColor $color
        }

    # 持续监控新增内容
    Get-Content $Path -Wait -Tail 0 |
        Where-Object { $_ -match $patternRegex } |
        ForEach-Object {
            $level = if ($_ -match 'ERROR|FATAL') { 'Error' } else { 'Warning' }
            $color = if ($level -eq 'Error') { 'Red' } else { 'Yellow' }
            $timestamp = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timestamp] $_" -ForegroundColor $color
        }
}

# 实时监控应用日志
Watch-LogFile -Path "C:\Logs\app.log" -Pattern @('ERROR', 'FATAL', 'WARN', 'Exception')
```

执行结果示例：

```
监控中：C:\Logs\app.log
过滤规则：ERROR|FATAL|WARN|Exception
按 Ctrl+C 停止

2025-05-21 08:15:32 ERROR [DB] Connection timeout after 30s
2025-05-21 08:20:18 WARN [CACHE] Cache miss rate > 50%
[08:25:45] 2025-05-21 08:25:45 ERROR [API] Upstream timeout (504)
```

## 注意事项

1. **大文件处理**：对于 GB 级别的日志文件，使用 `Get-Content -ReadCount 10000` 分批读取，或使用 `Select-String` 直接搜索避免全部加载到内存
2. **编码问题**：日志文件可能使用不同编码（UTF-8、GBK、UTF-16），使用 `Get-Content -Encoding` 指定正确编码
3. **正则性能**：复杂正则表达式在大文件上可能很慢，先用简单模式缩小范围再精细匹配
4. **时间格式**：不同应用的日志时间格式各异（ISO 8601、自定义格式），解析时注意时区转换
5. **日志轮转**：生产环境日志通常会轮转压缩（如 `app.log.2025-05-20.gz`），分析时需要考虑跨文件查询
6. **结构化日志**：新项目建议使用 JSON Lines 或类似的结构化日志格式，解析效率远高于正则提取
