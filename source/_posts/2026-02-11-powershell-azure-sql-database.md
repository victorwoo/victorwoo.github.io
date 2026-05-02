---
layout: post
date: 2026-02-11 08:00:00
updated: 2026-02-11 08:00:00
title: "PowerShell 技能连载 - Azure SQL 数据库管理"
description: "PowerTip of the Day - Azure SQL Database Management in PowerShell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- database
- cloud
---

_适用于 PowerShell 7.0 及以上版本_

Azure SQL Database 是微软 Azure 云平台上的托管关系数据库服务，基于最新的 SQL Server 数据库引擎提供企业级能力。它自动处理备份、补丁更新和高可用性配置，让 DBA 可以将精力集中在数据建模和查询优化上。然而，当管理数十甚至数百个数据库时，手动通过 Azure 门户操作不仅效率低下，还容易出现配置不一致的问题。

PowerShell 的 Az 模块提供了完整的 Azure SQL Database 管理 API 封装，支持从逻辑服务器创建、弹性池管理到安全策略配置的全生命周期操作。结合脚本化工作流，团队可以实现基础设施即代码（IaC），确保开发、测试和生产环境的数据库配置保持一致。

本文将通过三个实战场景，演示如何用 PowerShell 自动化 Azure SQL Database 的日常管理任务：数据库与服务器管理、安全与合规配置、性能监控与优化。每个场景都提供了可直接运行的脚本模板，帮助你快速构建自己的数据库管理工具集。

<!-- more -->

## 数据库与服务器管理

创建和管理 Azure SQL 逻辑服务器是所有数据库操作的基础。下面的脚本演示了如何创建逻辑服务器、配置弹性池、在池中创建数据库，以及批量查看资源状态。弹性池特别适合管理多个使用模式互补的小型数据库，通过共享 DTU 或 vCore 资源来降低成本。

```powershell
# 连接到 Azure 账户
Connect-AzAccount

# 定义变量
$ResourceGroupName = 'rg-sql-demo'
$Location = 'eastasia'
$ServerName = 'sql-demo-server-2026'
$AdminLogin = 'SqlAdmin'
$AdminPassword = ConvertTo-SecureString 'P@ssw0rd!2026#Strong' -AsPlainText -Force

# 创建资源组
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# 创建 Azure SQL 逻辑服务器
$Credential = New-Object System.Management.Automation.PSCredential($AdminLogin, $AdminPassword)
$Server = New-AzSqlServer `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -Location $Location `
    -SqlAdministratorCredentials $Credential `
    -ServerVersion '12.0'

Write-Host "逻辑服务器创建完成: $($Server.FullyQualifiedDomainName)"

# 创建弹性池（基于 DTU 模型）
$ElasticPool = New-AzSqlElasticPool `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -ElasticPoolName 'pool-shared' `
    -Edition 'Standard' `
    -Dtu '100' `
    -DatabaseDtuMin '10' `
    -DatabaseDtuMax '50'

Write-Host "弹性池创建完成: DTU=$($ElasticPool.Dtu), 最小=$($ElasticPool.DatabaseDtuMin), 最大=$($ElasticPool.DatabaseDtuMax)"

# 在弹性池中创建数据库
$DatabaseNames = @('db-orders', 'db-products', 'db-analytics')
foreach ($DbName in $DatabaseNames) {
    $Db = New-AzSqlDatabase `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $DbName `
        -ElasticPoolName 'pool-shared'

    Write-Host "数据库 '$DbName' 已创建于弹性池中，状态: $($Db.Status)"
}

# 创建独立数据库（vCore 模型，用于高负载场景）
$StandaloneDb = New-AzSqlDatabase `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -DatabaseName 'db-critical' `
    -ComputeGeneration 'Gen5' `
    -VCore 4 `
    -Edition 'GeneralPurpose'

Write-Host "独立数据库 'db-critical' 已创建: $($StandaloneDb.SkuName), vCore=$($StandaloneDb.Capacity)"

# 汇总查看服务器下所有数据库状态
$AllDatabases = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName
$AllDatabases | Select-Object DatabaseName, Status, SkuName, Capacity, ElasticPoolName |
    Format-Table -AutoSize
```

执行结果示例：

```
逻辑服务器创建完成: sql-demo-server-2026.database.windows.net
弹性池创建完成: DTU=100, 最小=10, 最大=50
数据库 'db-orders' 已创建于弹性池中，状态: Online
数据库 'db-products' 已创建于弹性池中，状态: Online
数据库 'db-analytics' 已创建于弹性池中，状态: Online
独立数据库 'db-critical' 已创建: GP_Gen5_4, vCore=4

DatabaseName   Status  SkuName    Capacity ElasticPoolName
------------   ------  -------    -------- ---------------
db-orders      Online  Standard   0        pool-shared
db-products    Online  Standard   0        pool-shared
db-analytics   Online  Standard   0        pool-shared
db-critical    Online  GP_Gen5_4  4
master         Online  System     0
```

## 安全与合规

数据库安全是云上运维的重中之重。Azure SQL Database 提供了多层安全防护：网络层的防火墙规则、数据层的透明数据加密（TDE）、操作层的审计日志、以及应用层的数据脱敏。下面的脚本演示了如何用 PowerShell 批量配置这些安全策略，确保所有数据库满足合规要求。

```powershell
$ResourceGroupName = 'rg-sql-demo'
$ServerName = 'sql-demo-server-2026'

# 配置服务器级防火墙规则：允许 Azure 服务访问
New-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -FirewallRuleName 'AllowAzureServices' `
    -StartIpAddress '0.0.0.0' `
    -EndIpAddress '0.0.0.0'

# 添加办公室 IP 白名单
New-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -FirewallRuleName 'OfficeNetwork' `
    -StartIpAddress '203.0.113.0' `
    -EndIpAddress '203.0.113.255'

# 查看所有防火墙规则
$FirewallRules = Get-AzSqlServerFirewallRule `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName

Write-Host "`n当前防火墙规则:"
$FirewallRules | Select-Object FirewallRuleName, StartIpAddress, EndIpAddress |
    Format-Table -AutoSize

# 为所有用户数据库启用透明数据加密（TDE）
$Databases = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName |
    Where-Object { $_.DatabaseName -ne 'master' }

foreach ($Db in $Databases) {
    $TdeStatus = Get-AzSqlDatabaseTransparentDataEncryption `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $Db.DatabaseName

    if ($TdeStatus.State -ne 'Enabled') {
        Set-AzSqlDatabaseTransparentDataEncryption `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $Db.DatabaseName `
            -State Enabled

        Write-Host "已为 '$($Db.DatabaseName)' 启用 TDE 加密"
    } else {
        Write-Host "'$($Db.DatabaseName)' TDE 已启用，跳过"
    }
}

# 配置服务器审计策略：将审计日志写入 Log Analytics
$Workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName 'rg-monitoring' -Name 'law-security'
Set-AzSqlServerAudit `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -LogAnalyticsTargetState Enabled `
    -WorkspaceResourceId $Workspace.ResourceId `
    -AuditActionGroup 'SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP',
                      'FAILED_DATABASE_AUTHENTICATION_GROUP',
                      'BATCH_COMPLETED_GROUP'

Write-Host "`n审计策略已配置，日志将写入 Log Analytics 工作区: $($Workspace.Name)"

# 配置数据脱敏策略（针对 db-orders 数据库中的敏感列）
$MaskingRules = @(
    @{
        Name         = 'MaskCreditCard'
        SchemaName   = 'dbo'
        TableName    = 'Payments'
        ColumnName   = 'CreditCardNumber'
        MaskingFunction = 'CreditCardNumber'
    },
    @{
        Name         = 'MaskEmail'
        SchemaName   = 'dbo'
        TableName    = 'Customers'
        ColumnName   = 'Email'
        MaskingFunction = 'Email'
    }
)

foreach ($Rule in $MaskingRules) {
    New-AzSqlDatabaseDataMaskingRule `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName 'db-orders' `
        -SchemaName $Rule.SchemaName `
        -TableName $Rule.TableName `
        -ColumnName $Rule.ColumnName `
        -MaskingFunction $Rule.MaskingFunction

    Write-Host "已添加数据脱敏规则: $($Rule.Name) -> $($Rule.TableName).$($Rule.ColumnName)"
}
```

执行结果示例：

```
当前防火墙规则:
FirewallRuleName   StartIpAddress EndIpAddress
----------------   -------------- ------------
AllowAzureServices 0.0.0.0        0.0.0.0
OfficeNetwork      203.0.113.0    203.0.113.255

已为 'db-orders' 启用 TDE 加密
已为 'db-products' 启用 TDE 加密
已为 'db-analytics' 启用 TDE 加密
'db-critical' TDE 已启用，跳过

审计策略已配置，日志将写入 Log Analytics 工作区: law-security
已添加数据脱敏规则: MaskCreditCard -> Payments.CreditCardNumber
已添加数据脱敏规则: MaskEmail -> Customers.Email
```

## 性能监控与优化

生产环境中的数据库性能直接影响应用响应时间和用户体验。Azure SQL Database 内置了智能性能分析功能，包括查询性能洞察、DTU/vCore 使用率监控、索引优化建议和自动调优。通过 PowerShell 可以定期采集这些指标，生成性能报告，并在指标超过阈值时触发告警。

```powershell
$ResourceGroupName = 'rg-sql-demo'
$ServerName = 'sql-demo-server-2026'

# 获取弹性池资源使用情况（过去 1 小时）
$EndTime = Get-Date
$StartTime = $EndTime.AddHours(-1)

$PoolMetrics = Get-AzMetric `
    -ResourceId "/subscriptions/$(Get-AzContext).Subscription.Id/resourceGroups/$ResourceGroupName/providers/Microsoft.Sql/servers/$ServerName/elasticPools/pool-shared" `
    -MetricName 'dtu_consumption_percent', 'storage_used_percent', 'sessions_percent' `
    -StartTime $StartTime `
    -EndTime $EndTime `
    -TimeGrain '00:05:00'

foreach ($Metric in $PoolMetrics) {
    $AvgValue = ($Metric.Data | Measure-Object Average -Average).Average
    $MaxValue = ($Metric.Data | Measure-Object Maximum -Maximum).Maximum
    Write-Host "$($Metric.Name): 平均=$([math]::Round($AvgValue, 1))%, 峰值=$([math]::Round($MaxValue, 1))%"
}

# 获取各数据库的 DTU 使用率排名
$Databases = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName |
    Where-Object { $_.DatabaseName -ne 'master' }

Write-Host "`n--- 数据库 DTU 使用率排名 ---"
$DbStats = foreach ($Db in $Databases) {
    $DbMetric = Get-AzMetric `
        -ResourceId $Db.ResourceId `
        -MetricName 'dtu_consumption_percent' `
        -StartTime $StartTime `
        -EndTime $EndTime `
        -TimeGrain '00:05:00'

    $AvgDtu = ($DbMetric.Data | Measure-Object Average -Average).Average
    [PSCustomObject]@{
        Database   = $Db.DatabaseName
        AvgDtuPct  = [math]::Round($AvgDtu, 1)
        Pool       = if ($Db.ElasticPoolName) { $db.ElasticPoolName } else { '(独立)' }
    }
}

$DbStats | Sort-Object AvgDtuPct -Descending | Format-Table -AutoSize

# 获取数据库索引优化建议
foreach ($Db in $Databases) {
    $Advisor = Get-AzSqlDatabaseAdvisor `
        -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $Db.DatabaseName `
        -AdvisorName 'CreateIndex'

    if ($Advisor.RecommendationsStatus -eq 'Active') {
        Write-Host "`n[$($Db.DatabaseName)] 索引建议:"
        $Actions = Get-AzSqlDatabaseRecommendedAction `
            -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $Db.DatabaseName `
            -AdvisorName 'CreateIndex' |
            Where-Object { $_.State.CurrentValue -eq 'Active' } |
            Select-Object -First 3

        foreach ($Action in $Actions) {
            $Impact = $Action.ImplementationDetails.EstimatedDiskSpaceChange
            Write-Host "  - $($Action.RecommendationReason) (预估空间: $Impact)"
        }
    }
}

# 启用自动调优：自动创建和删除索引
$AutoTuning = Set-AzSqlDatabaseAutoTuning `
    -ResourceGroupName $ResourceGroupName `
    -ServerName $ServerName `
    -DatabaseName 'db-critical' `
    -TuningOption 'CREATE_INDEX', 'DROP_INDEX' `
    -OptionMode Auto

Write-Host "`n自动调优已启用: $($AutoTuning.Options | ConvertTo-Json -Compress)"
```

执行结果示例：

```
dtu_consumption_percent: 平均=34.2%, 峰值=78.6%
storage_used_percent: 平均=12.5%, 峰值=12.8%
sessions_percent: 平均=8.1%, 峰值=22.3%

--- 数据库 DTU 使用率排名 ---
Database      AvgDtuPct Pool
--------      --------- ----
db-critical      45.2   (独立)
db-orders        28.7   pool-shared
db-analytics     19.3   pool-shared
db-products      12.1   pool-shared

[db-orders] 索引建议:
  - 缺少索引: dbo.Orders.CustomerId (预估空间: +15 MB)
  - 缺少索引: dbo.OrderItems.ProductId (预估空间: +8 MB)

[db-critical] 索引建议:
  - 缺少索引: dbo.Transactions.UserId (预估空间: +32 MB)

自动调优已启用: {"CREATE_INDEX":{"mode":"Auto"},"DROP_INDEX":{"mode":"Auto"}}
```

## 注意事项

1. **权限管理**：运行这些脚本需要 Azure RBAC 中的「SQL Server 参与者」角色或更高权限。建议使用托管标识（Managed Identity）而非服务主体密钥，避免凭据泄露风险。生产环境中应遵循最小权限原则，为不同操作分配不同角色。

2. **弹性池容量规划**：弹性池的 DTU/vCore 总量需要根据池内数据库的并发使用模式来规划。如果多个数据库同时出现高峰负载，可能导致资源争用。建议定期监控 `dtu_consumption_percent` 指标，当峰值持续超过 80% 时考虑扩容。

3. **防火墙规则安全**：`0.0.0.0` 规则允许所有 Azure 内部服务访问，虽然方便但存在风险。在生产环境中，应仅开放应用服务的出站 IP 地址段，并定期审计防火墙规则列表，清理不再使用的 IP 范围。

4. **TDE 加密性能影响**：透明数据加密对大多数工作负载的性能影响在 2%-5% 以内，但对于 I/O 密集型操作可能更高。启用 TDE 后不可关闭（Azure 托管数据库默认启用），自定义 TDE 保护器时务必备份证书，丢失将导致数据不可恢复。

5. **审计日志成本**：将审计日志发送到 Log Analytics 会产生数据摄入费用。高并发数据库可能每天产生数 GB 审计数据。建议配置保留策略（如热存储 30 天、归档 90 天），并只审计必要的操作组，而非全量记录。

6. **自动调优谨慎启用**：自动创建和删除索引功能在某些场景下可能产生意外行为，例如对写入密集的表频繁创建删除索引反而降低性能。建议先以「通知」模式运行一段时间，观察建议是否合理，再切换到「自动」模式。
