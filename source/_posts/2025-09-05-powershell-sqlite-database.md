---
layout: post
date: 2025-09-05 08:00:00
updated: 2025-09-05 08:00:00
title: "PowerShell 技能连载 - SQLite 数据库操作"
description: PowerTip of the Day - SQLite Database Operations in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- sqlite
- database
- data-storage
---

_适用于 PowerShell 5.1 及以上版本_

SQLite 是世界上最广泛部署的数据库引擎——每个 Android 手机、每个 Chrome 浏览器、每个 Windows 10 系统都内置了 SQLite。它无需安装数据库服务，整个数据库就是一个文件，这使得它非常适合脚本场景下的本地数据存储：日志归档、配置快照、审计记录、临时分析数据集。PowerShell 通过 .NET 的 `System.Data.SQLite` 或 `Microsoft.Data.Sqlite` 程序集可以方便地操作 SQLite 数据库。

本文将介绍 SQLite 在 PowerShell 中的完整操作流程。

<!-- more -->

## 数据库初始化与基本操作

```powershell
# 安装 SQLite 包（首次使用）
# Install-Package System.Data.SQLite.Core -Source nuget.org

# 或者使用简单的方式加载 DLL
Add-Type -Path "C:\Libs\System.Data.SQLite.dll"

# 数据库连接辅助函数
function Get-SqliteConnection {
    param([string]$DatabasePath)

    if (-not (Test-Path (Split-Path $DatabasePath))) {
        New-Item (Split-Path $DatabasePath) -ItemType Directory -Force | Out-Null
    }

    $connectionString = "Data Source=$DatabasePath;Version=3;Journal Mode=WAL;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    return $connection
}

# 初始化数据库
$dbPath = "C:\Data\Operations.db"
$conn = Get-SqliteConnection -DatabasePath $dbPath

# 创建表
$createTableSql = @"
CREATE TABLE IF NOT EXISTS ServerMetrics (
    Id         INTEGER PRIMARY KEY AUTOINCREMENT,
    ServerName TEXT    NOT NULL,
    MetricName TEXT    NOT NULL,
    Value      REAL,
    Unit       TEXT,
    Timestamp  TEXT    NOT NULL
);

CREATE TABLE IF NOT EXISTS AuditLog (
    Id         INTEGER PRIMARY KEY AUTOINCREMENT,
    Action     TEXT    NOT NULL,
    Target     TEXT,
    User       TEXT,
    Timestamp  TEXT    NOT NULL,
    Details    TEXT
);

CREATE INDEX IF NOT EXISTS idx_metrics_server ON ServerMetrics(ServerName);
CREATE INDEX IF NOT EXISTS idx_metrics_time ON ServerMetrics(Timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_time ON AuditLog(Timestamp);
"@

$cmd = $conn.CreateCommand()
$cmd.CommandText = $createTableSql
$cmd.ExecuteNonQuery()
Write-Host "数据库初始化完成：$dbPath" -ForegroundColor Green

# 插入数据
function Add-Metric {
    param(
        [System.Data.SQLite.SQLiteConnection]$Connection,
        [string]$ServerName,
        [string]$MetricName,
        [double]$Value,
        [string]$Unit = ""
    )

    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = "INSERT INTO ServerMetrics (ServerName, MetricName, Value, Unit, Timestamp) VALUES (@server, @metric, @value, @unit, @ts)"

    $cmd.Parameters.AddWithValue("@server", $ServerName)
    $cmd.Parameters.AddWithValue("@metric", $MetricName)
    $cmd.Parameters.AddWithValue("@value", $Value)
    $cmd.Parameters.AddWithValue("@unit", $Unit)
    $cmd.Parameters.AddWithValue("@ts", (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))

    $cmd.ExecuteNonQuery()
}

# 批量插入测试数据
$servers = @("SRV01", "SRV02", "SRV03")
$metrics = @(
    @{ Name = "CPUUsage";    Unit = "%" }
    @{ Name = "MemoryUsage"; Unit = "%" }
    @{ Name = "DiskFree";    Unit = "GB" }
)

foreach ($server in $servers) {
    foreach ($metric in $metrics) {
        $value = switch ($metric.Name) {
            "CPUUsage"    { Get-Random -Minimum 20 -Maximum 95 }
            "MemoryUsage" { Get-Random -Minimum 40 -Maximum 90 }
            "DiskFree"    { [math]::Round((Get-Random -Minimum 50 -Maximum 500) / 1.0, 2) }
        }
        Add-Metric -Connection $conn -ServerName $server -MetricName $metric.Name -Value $value -Unit $metric.Unit
    }
}

Write-Host "已插入测试数据" -ForegroundColor Green
$conn.Close()
```

执行结果示例：

```
数据库初始化完成：C:\Data\Operations.db
已插入测试数据
```

## 数据查询与分析

```powershell
# 查询数据
$conn = Get-SqliteConnection -DatabasePath $dbPath

# 基本查询
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT ServerName, MetricName, Value, Unit, Timestamp FROM ServerMetrics ORDER BY Timestamp DESC LIMIT 10"

$adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
$table = New-Object System.Data.DataTable
$adapter.Fill($table) | Out-Null

$table | Format-Table -AutoSize

# 使用参数化查询（防止 SQL 注入）
function Get-ServerMetrics {
    param(
        [System.Data.SQLite.SQLiteConnection]$Connection,
        [string]$ServerName,
        [int]$LastHours = 24
    )

    $startTime = (Get-Date).AddHours(-$LastHours).ToString("yyyy-MM-dd HH:mm:ss")

    $cmd = $Connection.CreateCommand()
    $cmd.CommandText = @"
SELECT ServerName, MetricName, AVG(Value) as AvgValue, MAX(Value) as MaxValue, MIN(Value) as MinValue
FROM ServerMetrics
WHERE ServerName = @server AND Timestamp >= @start
GROUP BY MetricName
"@

    $cmd.Parameters.AddWithValue("@server", $ServerName)
    $cmd.Parameters.AddWithValue("@start", $startTime)

    $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    $table = New-Object System.Data.DataTable
    $adapter.Fill($table) | Out-Null
    return $table
}

# 查询服务器指标汇总
$summary = Get-ServerMetrics -Connection $conn -ServerName "SRV01"
$summary | Format-Table -AutoSize

# 跨服务器对比查询
$cmd = $conn.CreateCommand()
$cmd.CommandText = @"
SELECT ServerName,
       ROUND(AVG(CASE WHEN MetricName='CPUUsage' THEN Value END), 2) as AvgCPU,
       ROUND(AVG(CASE WHEN MetricName='MemoryUsage' THEN Value END), 2) as AvgMemory,
       ROUND(AVG(CASE WHEN MetricName='DiskFree' THEN Value END), 2) as AvgDiskFree
FROM ServerMetrics
GROUP BY ServerName
ORDER BY AvgCPU DESC
"@

$adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
$compare = New-Object System.Data.DataTable
$adapter.Fill($compare) | Out-Null

Write-Host "`n服务器资源对比：" -ForegroundColor Cyan
$compare | Format-Table -AutoSize

$conn.Close()
```

执行结果示例：

```
ServerName MetricName    Value Unit Timestamp
---------- ----------    ----- ---- ---------
SRV03      DiskFree     345.67   GB 2025-09-05 14:30:15
SRV03      MemoryUsage   72.00    % 2025-09-05 14:30:15
SRV03      CPUUsage      45.00    % 2025-09-05 14:30:15
SRV02      DiskFree     123.45   GB 2025-09-05 14:30:15

服务器资源对比：
ServerName AvgCPU AvgMemory AvgDiskFree
---------- ------ --------- -----------
SRV01         67      78.5      234.56
SRV02         42      55.3      123.45
SRV03         45      72.0      345.67
```

## 数据库维护与备份

```powershell
# 数据库维护工具集
function Invoke-SqliteMaintenance {
    param(
        [Parameter(Mandatory)]
        [string]$DatabasePath,

        [ValidateSet("Analyze", "Optimize", "Integrity", "Backup")]
        [string]$Action = "Optimize"
    )

    $conn = Get-SqliteConnection -DatabasePath $DatabasePath

    switch ($Action) {
        "Analyze" {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "ANALYZE"
            $cmd.ExecuteNonQuery()
            Write-Host "统计信息已更新" -ForegroundColor Green
        }

        "Optimize" {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "VACUUM"
            $cmd.ExecuteNonQuery()
            Write-Host "数据库已压缩" -ForegroundColor Green

            $size = [math]::Round((Get-Item $DatabasePath).Length / 1KB, 2)
            Write-Host "当前大小：$size KB"
        }

        "Integrity" {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "PRAGMA integrity_check"
            $result = $cmd.ExecuteScalar()
            if ($result -eq "ok") {
                Write-Host "数据库完整性检查通过" -ForegroundColor Green
            } else {
                Write-Host "数据库完整性问题：$result" -ForegroundColor Red
            }
        }

        "Backup" {
            $backupPath = $DatabasePath -replace '\.db$', "_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').db"
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "VACUUM INTO '$backupPath'"
            $cmd.ExecuteNonQuery()
            Write-Host "备份已创建：$backupPath" -ForegroundColor Green
        }
    }

    $conn.Close()
}

# 执行维护操作
Invoke-SqliteMaintenance -DatabasePath $dbPath -Action Integrity
Invoke-SqliteMaintenance -DatabasePath $dbPath -Action Optimize
Invoke-SqliteMaintenance -DatabasePath $dbPath -Action Backup

# 数据导出工具
function Export-SqliteToCsv {
    param(
        [string]$DatabasePath,
        [string]$TableName,
        [string]$OutputPath
    )

    $conn = Get-SqliteConnection -DatabasePath $DatabasePath
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT * FROM $TableName"

    $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    $table = New-Object System.Data.DataTable
    $adapter.Fill($table) | Out-Null

    $table | Export-Csv $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "已导出 $($table.Rows.Count) 行到 $OutputPath" -ForegroundColor Green
    $conn.Close()
}

Export-SqliteToCsv -DatabasePath $dbPath -TableName "ServerMetrics" `
    -OutputPath "C:\Reports\ServerMetrics_$(Get-Date -Format 'yyyyMMdd').csv"
```

执行结果示例：

```
数据库完整性检查通过
数据库已压缩
当前大小：24.5 KB
备份已创建：C:\Data\Operations_backup_20250905_143015.db
已导出 9 行到 C:\Reports\ServerMetrics_20250905.csv
```

## 注意事项

1. **DLL 部署**：System.Data.SQLite 需要分平台部署（x86/x64），推荐使用 NuGet 包管理依赖
2. **并发写入**：SQLite 支持 WAL（Write-Ahead Logging）模式，允许读写并发，但多进程写入仍需注意锁冲突
3. **连接管理**：使用 `using` 语句或手动 `Close()` 确保连接释放，避免数据库文件被锁定
4. **数据类型**：SQLite 是动态类型系统，插入时不强制类型检查，查询结果可能需要手动转换
5. **数据库大小**：SQLite 理论上支持 140TB 的数据库，但实际使用中超过几 GB 后性能会下降
6. **备份策略**：生产数据应定期备份，可以使用 `VACUUM INTO` 命令创建一致性备份
