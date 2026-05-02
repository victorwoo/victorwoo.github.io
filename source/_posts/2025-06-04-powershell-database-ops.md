---
layout: post
date: 2025-06-04 08:00:00
updated: 2025-06-04 08:00:00
title: "PowerShell 技能连载 - 数据库运维自动化"
description: PowerTip of the Day - Database Operations Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- database
---

_适用于 PowerShell 5.1 及以上版本（Windows），需安装 SqlServer 模块_

数据库运维是后端团队最核心的日常任务之一——备份恢复、性能监控、索引维护、数据迁移，每项任务都需要精确操作。PowerShell 通过 `SqlServer` 模块（替代旧版 `SQLPS`）可以直接连接 SQL Server 执行查询和管理操作，将 DBA 的重复性工作自动化。

本文将讲解 SQL Server 的 PowerShell 管理技巧，包括备份恢复、性能监控、索引维护和数据迁移。

<!-- more -->

## 连接与查询

```powershell
# 安装 SqlServer 模块
Install-Module -Name SqlServer -Scope CurrentUser -Force

# 导入模块
Import-Module SqlServer

# 使用 Invoke-Sqlcmd 执行查询
$serverInstance = "localhost"
$database = "MyAppDB"

# 简单查询
$results = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $database -Query @"
    SELECT TOP 10
        name AS 表名,
        rows AS 行数,
        CAST(reserved AS FLOAT) / 1024 AS 已用MB
    FROM sys.tables t
    INNER JOIN sys.partitions p ON t.object_id = p.object_id
    ORDER BY rows DESC
"@

$results | Format-Table -AutoSize

# 带参数的查询（防止 SQL 注入）
$params = @{
    ServerInstance = $serverInstance
    Database       = $database
    Query          = "SELECT * FROM Users WHERE Department = @dept AND IsActive = 1"
    Variable       = @(
        (New-Object Microsoft.Data.SqlClient.SqlParameter('@dept', 'Engineering'))
    )
}

$users = Invoke-Sqlcmd @params
$users | Select-Object UserName, Email, CreatedDate |
    Format-Table -AutoSize
```

执行结果示例：

```
表名          行数     已用MB
----          ----     ------
Orders        1250000  456.78
Users         85000    32.45
Products      12000    8.92
AuditLog      5600000  1234.56

UserName   Email                    CreatedDate
--------   -----                    -----------
alice      alice@contoso.com        2024-03-15
bob        bob@contoso.com          2024-06-22
```

## 数据库备份与恢复

```powershell
function Backup-SqlDatabaseSafe {
    <#
    .SYNOPSIS
    执行 SQL Server 数据库备份
    #>
    param(
        [string]$ServerInstance = "localhost",
        [Parameter(Mandatory)]
        [string]$Database,
        [string]$BackupDir = "C:\Backups\SQL",
        [int]$RetainDays = 7
    )

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupFile = Join-Path $BackupDir "${Database}_${timestamp}.bak"

    # 确保备份目录存在
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null

    Write-Host "开始备份：$Database" -ForegroundColor Cyan

    Backup-SqlDatabase -ServerInstance $ServerInstance `
        -Database $Database `
        -BackupFile $backupFile `
        -CompressionOption On `
        -CopyOnly

    $size = [math]::Round((Get-Item $backupFile).Length / 1MB, 2)
    Write-Host "备份完成：$backupFile ($size MB)" -ForegroundColor Green

    # 清理过期备份
    Get-ChildItem $BackupDir -Filter "${Database}_*.bak" |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetainDays) } |
        ForEach-Object {
            Remove-Item $_.FullName -Force
            Write-Host "已清理：$($_.Name)" -ForegroundColor DarkGray
        }

    return $backupFile
}

# 执行备份
Backup-SqlDatabaseSafe -Database "MyAppDB" -RetainDays 7

# 恢复数据库
function Restore-SqlDatabaseSafe {
    param(
        [string]$ServerInstance = "localhost",
        [string]$Database,
        [Parameter(Mandatory)]
        [string]$BackupFile
    )

    Write-Host "恢复数据库：$Database" -ForegroundColor Yellow

    # 先设置单用户模式（断开所有连接）
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
        ALTER DATABASE [$Database] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
"@

    Restore-SqlDatabase -ServerInstance $ServerInstance `
        -Database $Database `
        -BackupFile $BackupFile `
        -ReplaceDatabase

    # 恢复多用户模式
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
        ALTER DATABASE [$Database] SET MULTI_USER
"@

    Write-Host "数据库恢复完成" -ForegroundColor Green
}
```

执行结果示例：

```
开始备份：MyAppDB
备份完成：C:\Backups\SQL\MyAppDB_20250604-080000.bak (234.56 MB)
已清理：MyAppDB_20250528-080000.bak
```

## 性能监控

```powershell
function Get-SqlPerformanceReport {
    <#
    .SYNOPSIS
    生成 SQL Server 性能报告
    #>
    param([string]$ServerInstance = "localhost")

    Write-Host "========== SQL Server 性能报告 ==========" -ForegroundColor Cyan

    # 1. 缓冲池使用率
    $bufferPool = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
        SELECT
            CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10,2)) AS 总缓存MB,
            CAST(SUM(CASE WHEN is_modified = 1 THEN 8 ELSE 0 END) / 1024.0 AS DECIMAL(10,2)) AS 脏页MB,
            CAST(SUM(CASE WHEN is_modified = 0 THEN 8 ELSE 0 END) / 1024.0 AS DECIMAL(10,2)) AS 干净页MB
        FROM sys.dm_os_buffer_descriptors
"@
    Write-Host "`n缓冲池：总 $($bufferPool.总缓存MB) MB, 脏页 $($bufferPool.脏页MB) MB"

    # 2. Top 10 慢查询
    $slowQueries = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
        SELECT TOP 10
            SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
                ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS 查询语句,
            qs.execution_count AS 执行次数,
            CAST(qs.total_elapsed_time / 1000000.0 AS DECIMAL(10,2)) AS 总耗时秒,
            CAST(qs.total_elapsed_time / 1000000.0 / qs.execution_count AS DECIMAL(10,4)) AS 平均耗时秒,
            qs.total_logical_reads AS 逻辑读取次数
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        ORDER BY qs.total_elapsed_time DESC
"@

    $slowQueries | Select-Object 查询语句, 执行次数, 总耗时秒, 平均耗时秒 |
        Format-Table -AutoSize -Wrap

    # 3. 阻塞会话
    $blocking = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
        SELECT
            blocking.session_id AS 阻塞源ID,
            blocked.session_id AS 被阻塞ID,
            DB_NAME(blocked.database_id) AS 数据库,
            blocked.wait_type AS 等待类型,
            blocked.wait_time/1000 AS 等待秒数,
            blocking_sql.text AS 阻塞源语句
        FROM sys.dm_exec_requests blocked
        JOIN sys.dm_exec_sessions blocking ON blocked.blocking_session_id = blocking.session_id
        CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_sql
        CROSS APPLY sys.dm_exec_sql_text(blocking.most_recent_sql_handle) blocking_sql
"@

    if ($blocking) {
        Write-Host "`n阻塞会话：" -ForegroundColor Red
        $blocking | Format-Table -AutoSize
    } else {
        Write-Host "`n无阻塞会话" -ForegroundColor Green
    }
}

Get-SqlPerformanceReport
```

执行结果示例：

```
========== SQL Server 性能报告 ==========

缓冲池：总 2048.00 MB, 脏页 128.50 MB

查询语句                                         执行次数 总耗时秒 平均耗时秒
--------                                         -------- -------- ----------
SELECT * FROM Orders WHERE...                          12456  345.67    0.0278
UPDATE Inventory SET qty...                             8234  234.12    0.0284

无阻塞会话
```

## 注意事项

1. **参数化查询**：始终使用参数化查询，不要拼接 SQL 字符串，防止 SQL 注入
2. **连接字符串安全**：使用 Windows 身份验证（Trusted_Connection）代替 SQL 身份验证，避免在脚本中暴露密码
3. **备份验证**：定期使用 `RESTORE VERIFYONLY` 验证备份文件的完整性
4. **长时间查询超时**：使用 `-QueryTimeout` 参数设置合理的超时，避免脚本无限等待
5. **维护窗口**：索引重建和统计更新应在低峰期执行，避免影响在线业务
6. **连接池**：频繁查询时考虑保持连接打开，或使用连接池减少连接开销
