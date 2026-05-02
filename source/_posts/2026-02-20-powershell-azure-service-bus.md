---
layout: post
date: 2026-02-20 08:00:00
updated: 2026-02-20 08:00:00
title: "PowerShell 技能连载 - Azure Service Bus 消息管理"
description: PowerTip of the Day - Azure Service Bus Messaging Management in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- service-bus
- messaging
- queue
---

_适用于 PowerShell 7.0 及以上版本_

在微服务架构日益普及的今天，服务之间的异步通信成为系统解耦的关键。Azure Service Bus 作为微软云端的企业级消息传递平台，提供了可靠的队列、主题和订阅模式，能够处理高吞吐量的消息流，并支持事务、会话和死信队列等高级特性。对于运维和开发团队来说，掌握如何通过 PowerShell 自动化管理这些资源，可以显著提升消息中间件的运维效率。

传统的 Service Bus 管理往往依赖 Azure 门户界面手动操作，或者通过 C# / Python 编写专门的管理工具。然而 PowerShell 凭借其与 Azure 生态的深度集成，能够以极低的代码量完成命名空间创建、队列配置、消息收发和监控告警等全套操作。结合自动化脚本和定时任务，可以实现 Service Bus 的全生命周期管理。

本文将从三个实战场景出发：命名空间与队列的基础管理、消息的发送与接收处理、以及队列的监控与运维，全面介绍如何用 PowerShell 构建 Service Bus 的自动化管理体系。

## 命名空间与队列管理

首先安装必要的 Azure 模块并连接到 Azure 订阅，然后创建 Service Bus 命名空间、队列和主题订阅等基础资源。

```powershell
# 安装并导入 Azure Service Bus 模块
Install-Module -Name Az.ServiceBus -Force -Scope CurrentUser
Import-Module Az.ServiceBus

# 连接到 Azure 账户
Connect-AzAccount -SubscriptionId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# 创建资源组和 Service Bus 命名空间
$resourceGroup = 'rg-servicebus-demo'
$location = 'eastasia'
$namespaceName = 'sb-psdemo-2026'

New-AzResourceGroup -Name $resourceGroup -Location $location -Force

$nsParams = @{
    ResourceGroupName = $resourceGroup
    Name              = $namespaceName
    Location          = $location
    SkuName           = 'Standard'
    Tag               = @{ Environment = 'Demo'; Owner = 'DevOps' }
}
$namespace = New-AzServiceBusNamespace @nsParams
Write-Host "命名空间已创建: $($namespace.Name)"

# 创建队列 - 配置消息 TTL、最大大小和重复检测
$queueParams = @{
    ResourceGroupName           = $resourceGroup
    NamespaceName               = $namespaceName
    Name                        = 'orders-queue'
    MaxSizeInMegabytes          = 1024
    DefaultMessageTimeToLive    = (New-TimeSpan -Days 7)
    DuplicateDetectionHistoryTimeWindow = (New-TimeSpan -Minutes 10)
    EnableExpress               = $false
    LockDuration                = (New-TimeSpan -Seconds 60)
    MaxDeliveryCount            = 5
    RequiresSession             = $false
}
$queue = New-AzServiceBusQueue @queueParams
Write-Host "队列已创建: $($queue.Name)"

# 创建主题和订阅
$topicParams = @{
    ResourceGroupName       = $resourceGroup
    NamespaceName           = $namespaceName
    Name                    = 'order-events'
    MaxSizeInMegabytes      = 2048
    DefaultMessageTimeToLive = (New-TimeSpan -Days 14)
    EnablePartitioning      = $true
}
$topic = New-AzServiceBusTopic @topicParams
Write-Host "主题已创建: $($topic.Name)"

# 为主题创建订阅，设置 SQL 过滤规则
$subParams = @{
    ResourceGroupName = $resourceGroup
    NamespaceName     = $namespaceName
    TopicName         = 'order-events'
    Name              = 'high-priority-sub'
    MaxDeliveryCount  = 10
}
$sub = New-AzServiceBusSubscription @subParams

# 添加 SQL 过滤规则 - 只接收高优先级订单
$ruleParams = @{
    ResourceGroupName = $resourceGroup
    NamespaceName     = $namespaceName
    TopicName         = 'order-events'
    SubscriptionName  = 'high-priority-sub'
    Name              = 'PriorityFilter'
    SqlFilter         = "Priority = 'High'"
}
New-AzServiceBusRule @ruleParams
Write-Host "订阅和过滤规则已创建"
```

执行结果示例：

```
命名空间已创建: sb-psdemo-2026
队列已创建: orders-queue
主题已创建: order-events
订阅和过滤规则已创建

# 查看命名空间详情
Get-AzServiceBusNamespace -ResourceGroupName rg-servicebus-demo -Name sb-psdemo-2026 |
    Select-Object Name, Location, SkuName, ProvisioningState

Name             Location SkuName  ProvisioningState
----             -------- -------  -----------------
sb-psdemo-2026   eastasia Standard Succeeded
```

## 消息发送与接收

使用 Azure Service Bus 的 REST API 通过 PowerShell 发送和接收消息，包括批量发送和死信队列处理。

```powershell
# 获取命名空间的连接字符串，用于消息操作
$authRule = Get-AzServiceBusAuthorizationRule `
    -ResourceGroupName $resourceGroup `
    -NamespaceName $namespaceName `
    -Name 'RootManageSharedAccessKey'

$connectionString = (Get-AzServiceBusKey `
    -ResourceGroupName $resourceGroup `
    -NamespaceName $namespaceName `
    -AuthorizationRuleName 'RootManageSharedAccessKey').PrimaryConnectionString

Write-Host "连接字符串已获取，用于后续消息操作"

# 使用 Service Bus REST API 发送单条消息
# 首先获取 SAS Token
function Get-SbSasToken {
    param(
        [string]$ConnectionString,
        [int]$ExpiryMinutes = 60
    )
    $parts = $ConnectionString -split ';'
    $endpoint = ($parts | Where-Object { $_ -match '^Endpoint=' }) -replace '^Endpoint=sb://', '' -replace '/$', ''
    $sasKey = ($parts | Where-Object { $_ -match '^SharedAccessKey=' }) -replace '^SharedAccessKey=', ''
    $sasName = ($parts | Where-Object { $_ -match '^SharedAccessKeyName=' }) -replace '^SharedAccessKeyName=', ''

    $expiry = [DateTimeOffset]::UtcNow.AddMinutes($ExpiryMinutes).ToUnixTimeSeconds()
    $stringToSign = [System.Web.HttpUtility]::UrlEncode("https://$endpoint") + "`n$expiry"
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 `
        (,[System.Convert]::FromBase64String($sasKey))
    $signature = [System.Convert]::ToBase64String(
        $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign)))
    $token = "SharedAccessSignature sr=$([System.Web.HttpUtility]::UrlEncode("https://$endpoint"))&sig=$([System.Web.HttpUtility]::UrlEncode($signature))&se=$expiry&skn=$sasName"
    return $token, $endpoint
}

# 发送消息到队列
$token, $endpoint = Get-SbSasToken -ConnectionString $connectionString
$queueName = 'orders-queue'
$messageBody = @{
    orderId   = "ORD-$(Get-Random -Maximum 99999)"
    customer  = '张三'
    amount    = 299.50
    priority  = 'High'
    timestamp = (Get-Date).ToString('o')
} | ConvertTo-Json -Compress

$sendUri = "https://$endpoint/$queueName/messages"
$headers = @{
    Authorization          = $token
    'Content-Type'         = 'application/atom+xml;type=entry;charset=utf-8'
    'BrokerProperties'     = (@{ Label = 'NewOrder'; MessageId = [Guid]::NewGuid().ToString() } | ConvertTo-Json -Compress)
}

# 批量发送消息示例
$batchCount = 5
for ($i = 1; $i -le $batchCount; $i++) {
    $body = @{
        orderId    = "ORD-$(Get-Random -Maximum 99999)"
        batchIndex = $i
        customer   = "客户$i"
        amount     = [math]::Round((Get-Random -Minimum 10 -Maximum 500), 2)
        priority   = if ($i % 2 -eq 0) { 'High' } else { 'Normal' }
        timestamp  = (Get-Date).ToString('o')
    } | ConvertTo-Json -Compress

    $headers['BrokerProperties'] = (@{
        Label     = "BatchMessage-$i"
        MessageId = [Guid]::NewGuid().ToString()
    } | ConvertTo-Json -Compress)

    $response = Invoke-RestMethod -Uri $sendUri -Method Post -Headers $headers -Body $body
    Write-Host "消息 $i 已发送 (StatusCode: OK)"
}

# 查看死信队列中的消息数量
$dlqPath = "$queueName/$deadletter"
$dlqUri = "https://$endpoint/$queueName`$deadletter/messages"
Write-Host "`n死信队列路径: $dlqPath"

# 清理消息 - 使用 Azure CLI 辅助操作
# az servicebus queue show --resource-group $resourceGroup --namespace-name $namespaceName --name $queueName
```

执行结果示例：

```
连接字符串已获取，用于后续消息操作
消息 1 已发送 (StatusCode: OK)
消息 2 已发送 (StatusCode: OK)
消息 3 已发送 (StatusCode: OK)
消息 4 已发送 (StatusCode: OK)
消息 5 已发送 (StatusCode: OK)

死信队列路径: orders-queue/$deadletter

# 队列当前状态
$queueInfo = Get-AzServiceBusQueue -ResourceGroupName $resourceGroup -NamespaceName $namespaceName -Name 'orders-queue'
$queueInfo | Select-Object Name, MessageCount, SizeInMegabytes

Name          MessageCount SizeInMegabytes
----          ------------ ---------------
orders-queue              5            0.01
```

## 监控与运维

构建 Service Bus 的健康监控体系，包括队列深度检查、消息积压告警和性能指标报告。

```powershell
# 定义监控函数 - 检查所有队列的健康状态
function Get-SbQueueHealth {
    param(
        [string]$ResourceGroupName,
        [string]$NamespaceName,
        [int]$WarningThreshold = 100,
        [int]$CriticalThreshold = 500
    )

    $queues = Get-AzServiceBusQueue -ResourceGroupName $ResourceGroupName `
        -NamespaceName $NamespaceName

    $report = foreach ($q in $queues) {
        $status = switch ($true) {
            ($q.MessageCount -ge $CriticalThreshold) { 'CRITICAL'; break }
            ($q.MessageCount -ge $WarningThreshold)  { 'WARNING'; break }
            default                                   { 'HEALTHY'; break }
        }

        # 计算死信队列占比
        $dlqCount = if ($q.CountDetails) {
            $q.CountDetails.DeadLetterMessageCount
        } else { 0 }
        $dlqRatio = if ($q.MessageCount -gt 0) {
            [math]::Round(($dlqCount / $q.MessageCount) * 100, 2)
        } else { 0 }

        [PSCustomObject]@{
            QueueName           = $q.Name
            MessageCount        = $q.MessageCount
            ActiveMessages      = $q.CountDetails.ActiveMessageCount
            DeadLetterCount     = $dlqCount
            DeadLetterRatio     = "$dlqRatio%"
            ScheduledCount      = $q.CountDetails.ScheduledMessageCount
            Status              = $status
            MaxSizeMB           = $q.MaxSizeInMegabytes
            CurrentSizeMB       = [math]::Round($q.SizeInMegabytes, 2)
            SizeUtilization     = "$([math]::Round(($q.SizeInMegabytes / $q.MaxSizeInMegabytes) * 100, 2))%"
            LastUpdated         = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }

    return $report
}

# 执行健康检查
$health = Get-SbQueueHealth `
    -ResourceGroupName $resourceGroup `
    -NamespaceName $namespaceName `
    -WarningThreshold 50 `
    -CriticalThreshold 200

$health | Format-Table -AutoSize

# 生成监控报告并导出
$reportDate = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$csvPath = "./sb-health-report-$reportDate.csv"
$health | Export-Csv -Path $csvPath -NoTypeInformation -Encoding Utf8
Write-Host "健康报告已导出至: $csvPath"

# 发送告警邮件（如果存在 CRITICAL 队列）
$criticalQueues = $health | Where-Object { $_.Status -eq 'CRITICAL' }
if ($criticalQueues) {
    $alertBody = "以下 Service Bus 队列消息积压严重：`n"
    foreach ($cq in $criticalQueues) {
        $alertBody += "  - $($cq.QueueName): $($cq.MessageCount) 条消息 (状态: $($cq.Status))`n"
    }
    $alertBody += "`n请尽快处理。`n报告时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    Write-Host "=== 告警通知 ===" -ForegroundColor Red
    Write-Host $alertBody
    # 实际发送可集成 Send-MailMessage 或企业微信/钉钉 Webhook
}

# 持续监控循环（示例：每 30 秒检查一次）
function Start-SbContinuousMonitor {
    param(
        [string]$ResourceGroupName,
        [string]$NamespaceName,
        [int]$IntervalSeconds = 30,
        [int]$DurationMinutes = 5
    )

    $endTime = (Get-Date).AddMinutes($DurationMinutes)
    $iteration = 0

    Write-Host "开始持续监控 (间隔: ${IntervalSeconds}s, 持续: ${DurationMinutes}min)"
    Write-Host ('=' * 60)

    while ((Get-Date) -lt $endTime) {
        $iteration++
        $timestamp = Get-Date -Format 'HH:mm:ss'
        Write-Host "`n[$timestamp] 第 $iteration 次检查..."

        $queues = Get-AzServiceBusQueue `
            -ResourceGroupName $ResourceGroupName `
            -NamespaceName $NamespaceName

        foreach ($q in $queues) {
            $activeCount = $q.CountDetails.ActiveMessageCount
            $dlqCount = $q.CountDetails.DeadLetterMessageCount
            Write-Host "  $($q.Name): 活跃=$activeCount, 死信=$dlqCount"

            if ($activeCount -gt 200) {
                Write-Host "  [WARNING] $($q.Name) 消息积压: $activeCount 条" -ForegroundColor Yellow
            }
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
    Write-Host "`n监控已结束，共执行 $iteration 次检查。"
}

# 启动持续监控（取消注释以运行）
# Start-SbContinuousMonitor -ResourceGroupName $resourceGroup -NamespaceName $namespaceName -DurationMinutes 10
```

执行结果示例：

```
QueueName      MessageCount ActiveMessages DeadLetterCount DeadLetterRatio ScheduledCount Status  MaxSizeMB CurrentSizeMB SizeUtilization LastUpdated
---------      ------------ -------------- --------------- --------------- -------------- ------  --------- ------------- --------------- -----------
orders-queue               5              5               0 0%                          0 HEALTHY      1024          0.01 0%              2026-02-20 08:15:32
events-queue             180            175               5 2.78%                        0 WARNING      1024          3.45 0.34%            2026-02-20 08:15:32
retry-queue              520            510              10 1.92%                        0 CRITICAL     1024          8.20 0.8%              2026-02-20 08:15:32

健康报告已导出至: ./sb-health-report-2026-02-20_081532.csv

=== 告警通知 ===
以下 Service Bus 队列消息积压严重：
  - retry-queue: 520 条消息 (状态: CRITICAL)

请尽快处理。
报告时间: 2026-02-20 08:15:32
```

## 注意事项

1. **连接字符串安全**：获取 Service Bus 连接字符串后应妥善保管，建议存储在 Azure Key Vault 中，避免在脚本中硬编码敏感信息。生产环境推荐使用 Managed Identity 替代共享访问密钥。

2. **消息大小限制**：Standard 层级的消息最大为 256 KB，Premium 层级支持最大 100 MB。超过限制的消息需要压缩或拆分，否则会被拒绝。

3. **定价层级选择**：Standard 层按消息数量计费，适合中低吞吐量场景；Premium 层按资源单位计费，提供独立资源和更高性能，适合生产环境的关键业务。命名空间一旦创建，SKU 不可更改，只能删除重建。

4. **死信队列监控**：消息超过最大投递次数（MaxDeliveryCount）后会自动进入死信队列。务必定期检查死信队列，分析失败原因并修复问题，避免业务消息丢失。

5. **REST API 限制**：通过 REST API 操作消息时需注意请求频率限制。高频场景建议使用 AMQP 协议的专用客户端库（如 Azure.Messaging.ServiceBus），或通过 Azure Functions 事件触发方式处理消息。

6. **监控告警集成**：生产环境中应将队列监控与 Azure Monitor 告警规则集成，配合 Action Group 实现自动通知。PowerShell 脚本适合定时巡检和运维自动化，但不宜作为唯一的监控手段。
