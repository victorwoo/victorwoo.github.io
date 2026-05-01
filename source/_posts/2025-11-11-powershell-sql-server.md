---
layout: post
date: 2025-11-11 08:00:00
title: "PowerShell 技能连载 - SQL Server 管理"
description: PowerTip of the Day - SQL Server Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- sql-server
- database
- smo
- dba
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

SQL Server 是企业级关系型数据库的常青树，广泛应用于金融、制造、零售等行业。作为 DBA 或运维工程师，日常需要频繁执行实例巡检、数据库备份、性能监控、空间分析等操作。传统做法是通过 SQL Server Management Studio（SSMS）手工完成，但面对多实例、多数据库的环境，图形界面操作效率低下且容易遗漏。PowerShell 凭借其强大的自动化能力和丰富的 SQL Server 模块生态，让这些任务变得可编程、可复用、可调度。

微软提供的 `SqlServer` 模块封装了 SQL Server Management Objects（SMO）库，几乎覆盖了 SSMS 能做的所有事情。从查询实例信息、管理数据库文件，到执行 T-SQL、配置安全策略，都可以通过 PowerShell 脚本完成。结合 Windows 任务计划或 SQL Agent Job，还能实现定时自动巡检和告警推送，大幅减轻 DBA 的重复劳动负担。

本文将从连接实例、查询元数据、执行 T-SQL、监控数据库空间四个典型场景入手，演示如何用 PowerShell 高效管理 SQL Server，帮助你建立一套实用的数据库自动化运维脚本库。

## 连接 SQL Server 实例并获取基本信息

管理 SQL Server 的第一步是建立连接。`SqlServer` 模块提供了 `Connect-SqlInstance` 命令，返回一个 SMO `Server` 对象，通过它可以访问实例级别和数据库级别的几乎所有属性。

```powershell
# 安装 SqlServer 模块（如尚未安装）
Install-Module SqlServer -Force -Scope CurrentUser

# 连接到本地默认实例（使用 Windows 集成身份验证）
$instance = Connect-SqlInstance -ServerInstance "localhost"

# 输出实例基本信息
[PSCustomObject]@{
    InstanceName   = $instance.Name
    Version        = $instance.VersionString
    Edition        = $instance.Edition
    ProductLevel   = $instance.ProductLevel
    Platform       = $instance.Platform
    HostName       = $instance.NetName
    Collation      = $instance.Collation
    LoginMode      = $instance.LoginMode
    IsClustered    = $instance.IsClustered
}
```

执行结果示例：

```
InstanceName   : localhost
Version        : 16.0.1113.5
Edition        : Developer Edition (64-bit)
ProductLevel   : RTM
Platform       : Windows NT x64 <x64>
HostName       : DB-SERVER01
Collation      : Chinese_PRC_CI_AS
LoginMode      : Integrated
IsClustered    : False
```

`Connect-SqlInstance` 默认使用当前 Windows 凭据进行身份验证，也支持 SQL 身份验证（通过 `-Credential` 参数）。返回的 `Server` 对象包含了实例的版本、版本级别、排序规则、登录模式等关键信息，可用于后续的条件判断和兼容性检查。如果环境中有多台服务器，可以将实例名存放在配置文件或 CSV 中，用循环批量连接巡检。

## 查询所有数据库的状态和空间使用

数据库状态和空间使用情况是 DBA 日常巡检的核心指标。SMO 的 `Databases` 集合为每个数据库提供了丰富的属性，无需手写 T-SQL 即可获取结构化的空间信息。

```powershell
# 连接实例
$instance = Connect-SqlInstance -ServerInstance "localhost"

# 遍历所有用户数据库，收集状态和空间信息
$dbStats = foreach ($db in $instance.Databases) {
    # 跳过系统数据库（可选）
    if ($db.IsSystemObject) { continue }

    [PSCustomObject]@{
        DatabaseName    = $db.Name
        Status          = $db.Status
        RecoveryModel   = $db.RecoveryModel
        SizeMB          = [math]::Round($db.Size, 2)
        DataSpaceMB     = [math]::Round(
            ($db.FileGroups | ForEach-Object { $_.Files } |
                Measure-Object -Property Size -Sum).Sum / 1024, 2
        )
        LogSpaceMB      = [math]::Round(
            ($db.LogFiles | Measure-Object -Property Size -Sum).Sum / 1024, 2
        )
        LastBackupDate  = $db.LastBackupDate
        CreateDate      = $db.CreateDate
    }
}

# 按大小降序排列并输出
$dbStats | Sort-Object SizeMB -Descending | Format-Table -AutoSize
```

执行结果示例：

```
DatabaseName Status   RecoveryModel SizeMB DataSpaceMB LogSpaceMB LastBackupDate       CreateDate
------------ ------   ------------- ------ ----------- ---------- --------------       ----------
SalesDB      Normal   Full          2048.5        1800      248.5 2025/11/10 02:00:00  2024/03/15 10:30:00
AppLog       Normal   Simple        1024.0         900      124.0 2025/11/11 00:30:00  2024/06/20 14:15:00
TestDB       Normal   Simple         512.0         450       62.0 2025/11/09 22:00:00  2025/01/10 09:00:00
```

`$db.Size` 以 MB 为单位返回数据库总大小（数据文件和日志文件之和）。通过遍历 `FileGroups.Files` 和 `LogFiles` 集合，可以分别计算数据空间和日志空间的占比，及时发现日志文件异常膨胀的问题。`LastBackupDate` 字段能快速定位长时间未备份的数据库，是安全巡检的必检项。

## 执行 T-SQL 查询并处理结果

除了通过 SMO 对象访问元数据，很多场景下需要直接执行 T-SQL 语句来查询动态管理视图或业务数据。`Invoke-Sqlcmd` 是 `SqlServer` 模块中最常用的命令，支持执行任意 T-SQL 并将结果以 `DataRow` 对象的形式返回。

```powershell
# 查询当前实例中活跃会话和阻塞情况
$query = @"
SELECT
    session_id,
    DB_NAME(database_id) AS DatabaseName,
    status,
    wait_type,
    wait_time_ms,
    blocking_session_id,
    cpu_time,
    reads,
    writes,
    logical_reads,
    start_time
FROM sys.dm_exec_requests
WHERE session_id > 50
ORDER BY start_time
"@

$results = Invoke-Sqlcmd -ServerInstance "localhost" -Query $query

# 筛选被阻塞的会话
$blocked = $results | Where-Object { $_.blocking_session_id -ne 0 }

if ($blocked) {
    Write-Host "检测到阻塞会话:" -ForegroundColor Yellow
    foreach ($row in $blocked) {
        [PSCustomObject]@{
            SessionId    = $row.session_id
            Database     = $row.DatabaseName
            Status       = $row.status
            WaitType     = $row.wait_type
            WaitTimeMs   = $row.wait_time_ms
            BlockedBy    = $row.blocking_session_id
            StartTime    = $row.start_time
        }
    }
} else {
    Write-Host "当前无阻塞会话" -ForegroundColor Green
}
```

执行结果示例：

```
检测到阻塞会话:

SessionId Database Status WaitType         WaitTimeMs BlockedBy StartTime
--------- -------- ------ --------         ---------- --------- ---------
       58 SalesDB  running LCK_M_S                   4520        52 2025/11/11 09:15:30
       61 SalesDB  suspended LCK_M_S                  850        52 2025/11/11 09:16:10
```

`Invoke-Sqlcmd` 的 `-Query` 参数接受任意 T-SQL 文本，也可以通过 `-InputFile` 参数执行 `.sql` 文件。查询 `sys.dm_exec_requests` 视图是排查阻塞问题的常用手段，`blocking_session_id` 不为 0 表示该会话正在被另一个会话阻塞。将这段脚本配置为定时任务，每 5 分钟执行一次并发送告警邮件，就能实现自动化的阻塞监控。

## 批量检查数据库备份状态

备份是数据库安全的最后一道防线。以下脚本批量检查所有用户数据库的备份状态，识别出超过阈值未备份或从未备份的数据库，并生成结构化报告。

```powershell
# 连接实例并定义备份阈值（小时）
$instance = Connect-SqlInstance -ServerInstance "localhost"
$thresholdHours = 24
$cutoffTime = (Get-Date).AddHours(-$thresholdHours)

# 检查备份状态
$backupReport = foreach ($db in $instance.Databases) {
    if ($db.IsSystemObject) { continue }

    $lastFull    = $db.LastBackupDate
    $lastDiff    = $db.LastDifferentialBackupDate
    $lastLog     = $db.LastLogBackupDate
    $recoveryModel = $db.RecoveryModel.ToString()

    $riskLevel = "正常"
    if ($lastFull -eq [datetime]::MinValue) {
        $riskLevel = "高风险"
    } elseif ($lastFull -lt $cutoffTime) {
        $riskLevel = "警告"
    }

    [PSCustomObject]@{
        Database        = $db.Name
        RiskLevel       = $riskLevel
        RecoveryModel   = $recoveryModel
        LastFullBackup  = if ($lastFull -eq [datetime]::MinValue) { "从未备份" } else { $lastFull }
        LastDiffBackup  = if ($lastDiff -eq [datetime]::MinValue) { "无" } else { $lastDiff }
        LastLogBackup   = if ($lastLog -eq [datetime]::MinValue) { "无" } else { $lastLog }
    }
}

# 按风险等级排序输出
$backupReport | Sort-Object RiskLevel | Format-Table -AutoSize
```

执行结果示例：

```
Database    RiskLevel RecoveryModel LastFullBackup        LastDiffBackup        LastLogBackup
--------    --------- ------------- --------------        --------------        -------------
SalesDB     正常      Full          2025/11/11 02:00:00   2025/11/11 06:00:00   2025/11/11 08:45:00
AppLog      正常      Simple        2025/11/11 00:30:00   无                    无
StagingDB   警告      Simple        2025/11/09 22:00:00   无                    无
ArchiveDB   高风险    Full          从未备份              无                    无
```

通过 `$db.LastBackupDate` 判断最后一次完整备份的时间，与阈值比较后划分为"正常""警告""高风险"三个等级。对于使用完整恢复模式（Full Recovery Model）的数据库，还需要额外关注日志备份频率，否则事务日志会持续增长。将此脚本接入监控系统，每天自动执行并推送异常结果，可以有效防止备份遗漏导致的数据丢失风险。

## 注意事项

1. **模块选择**：`SqlServer` 模块是 `SQLPS` 的继任者，建议始终使用 `SqlServer`。如果环境中同时安装了两个模块，可能产生命名冲突。可通过 `Get-Module -ListAvailable SqlServer` 确认版本，建议使用 22.x 以上版本以获得完整的 SMO 支持。

2. **连接安全**：生产环境建议使用 Windows 集成身份验证，避免在脚本中硬编码 SQL 账号密码。如果必须使用 SQL 身份验证，密码应存放在 PowerShell 凭据对象中（`Get-Credential`）或通过 Azure Key Vault / Windows Credential Manager 安全读取，绝不能以明文形式写入脚本文件。

3. **防火墙与端口**：连接远程 SQL Server 实例时，确保目标服务器的 1433 端口（或自定义端口）已在防火墙中放行，且 SQL Server 配置管理器中已启用 TCP/IP 协议。命名实例还需要 SQL Server Browser 服务运行在 1434 端口上才能正确解析动态端口。

4. **SMO 对象生命周期**：`Connect-SqlInstance` 返回的 `Server` 对象持有数据库连接，在长时间运行的脚本中（如循环处理数百个数据库），建议在操作完成后调用 `$instance.ConnectionContext.Disconnect()` 主动释放连接，避免占用过多数据库连接数。

5. **错误处理**：执行 T-SQL 或访问 SMO 属性时，应使用 `try/catch` 包裹关键操作。例如数据库处于恢复状态时访问 `$db.Size` 会抛出异常。对于批量巡检脚本，单库异常不应中断整个流程，建议收集错误信息后统一输出报告。

6. **性能考量**：`Invoke-Sqlcmd` 默认将整个结果集加载到内存，对于返回大量行的查询（如审计日志全表扫描），可能导致内存占用过高。可以通过 `-MaxCharLength` 和 `-MaxBinaryLength` 参数控制字段截断长度，或在 T-SQL 中使用 `TOP` 子句限制行数。对于海量数据导出场景，建议使用 `bcp` 工具或 `SqlBulkCopy` 类。
