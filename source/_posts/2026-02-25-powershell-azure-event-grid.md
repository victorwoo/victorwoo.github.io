---
layout: post
date: 2026-02-25 08:00:00
updated: 2026-02-25 08:00:00
title: "PowerShell 技能连载 - Azure Event Grid 事件驱动自动化"
description: PowerTip of the Day - Azure Event Grid Event-Driven Automation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- azure
- event-grid
- event-driven
- automation
---

_适用于 PowerShell 7.0 及以上版本_

## 背景

在云原生架构中，事件驱动模式正逐渐取代传统轮询方式，成为系统间解耦通信的主流方案。Azure Event Grid 是微软 Azure 提供的完全托管事件路由服务，它基于发布-订阅模型，可以近乎实时地将 Azure 资源的状态变更事件分发给订阅者。无论是虚拟机启动、存储 Blob 上传，还是自定义业务事件，Event Grid 都能可靠地完成投递。

对于运维工程师和自动化开发者来说，将 PowerShell 与 Event Grid 结合可以构建强大的事件响应流水线。想象一下这样的场景：当生产环境的虚拟机被意外删除时，Event Grid 立即推送事件到你的 PowerShell 脚本，脚本自动验证操作合法性、记录审计日志、并通过 Teams 发送告警——整个过程无需人工介入，响应时间从分钟级缩短到秒级。

本文将从三个层面展开：首先介绍如何用 PowerShell 管理 Event Grid 主题与订阅，然后演示事件的发布与高级处理，最后通过一个完整的自动化实战案例，展示如何将 Event Grid 融入日常运维工作流。

## Event Grid 主题与订阅管理

在使用 Event Grid 之前，需要先创建事件主题（Topic）和事件订阅（Event Subscription）。主题是事件的入口，订阅者通过事件订阅声明自己关注哪些事件。下面的脚本展示了如何使用 `Az` 模块完成这些操作。

```powershell
# 连接 Azure 账户并选择订阅
Connect-AzAccount -Subscription 'production-sub'

# 定义资源组和主题名称
$ResourceGroup = 'rg-eventgrid-demo'
$Location = 'eastus'
$TopicName = 'custom-ops-events'

# 创建资源组（如果不存在）
if (-not (Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location
}

# 创建自定义 Event Grid 主题
$Topic = New-AzEventGridTopic `
    -ResourceGroupName $ResourceGroup `
    -Name $TopicName `
    -Location $Location

Write-Host "主题已创建: $($Topic.Endpoint)"

# 为主题创建事件订阅，使用 Webhook 作为端点
$WebhookEndpoint = 'https://ps-webhook.example.com/api/eventhandler'
$SubscriptionName = 'ops-alert-sub'

$EventSubscription = New-AzEventGridSubscription `
    -EventSubscriptionName $SubscriptionName `
    -ResourceId $Topic.Id `
    -Endpoint $WebhookEndpoint `
    -EndpointType webhook `
    -IncludedEventType @(
        'Ops.VM.Created'
        'Ops.VM.Deleted'
        'Ops.Storage.Uploaded'
    ) `
    -SubjectBeginsWith '/operations/production/' `
    -SubjectEndsWith '/critical'

Write-Host "事件订阅已创建: $SubscriptionName"
Write-Host "过滤规则: 仅接收生产环境关键操作事件"

# 查看所有事件订阅
Get-AzEventGridSubscription `
    -ResourceId $Topic.Id |
    Select-Object Name, EventDeliverySchema, Destination |
    Format-List
```

执行结果示例：

```
主题已创建: https://custom-ops-events.eastus-1.eventgrid.azure.net/api/events
事件订阅已创建: ops-alert-sub
过滤规则: 仅接收生产环境关键操作事件

Name                 : ops-alert-sub
EventDeliverySchema  : EventGridSchema
Destination          : Microsoft.EventGrid/Webhook
```

上面创建了自定义主题并配置了 Webhook 订阅。注意 `IncludedEventType` 参数只订阅了三种特定事件类型，`SubjectBeginsWith` 和 `SubjectEndsWith` 进一步缩小了事件范围——这种精细化过滤能有效减少无用事件的投递，降低下游处理压力。

## 事件发布与处理

主题和订阅就绪后，接下来就是发布和处理事件。PowerShell 可以通过 REST API 向 Event Grid 发送自定义事件，同时也能作为 Webhook 处理端接收并解析事件。下面展示完整的发布和处理流程。

```powershell
# --- 发布自定义事件 ---

# 获取主题的访问密钥
$Keys = Get-AzEventGridTopicKey `
    -ResourceGroupName $ResourceGroup `
    -TopicName $TopicName

# 构造符合 Event Grid 架构的事件负载
$EventId = [Guid]::NewGuid().ToString()
$EventTime = (Get-Date).ToUniversalTime().ToString('o')

$EventPayload = @(
    @{
        id        = $EventId
        eventType = 'Ops.VM.Created'
        subject   = '/operations/production/vm/web-01/critical'
        eventTime = $EventTime
        data = @{
            vmName     = 'web-01'
            resourceGroup = 'rg-production'
            createdBy  = 'admin@vichamp.com'
            vmSize     = 'Standard_D4s_v3'
            tags = @{
                Environment = 'Production'
                AutoShutdown = 'true'
            }
        }
        dataVersion = '1.0'
    }
) | ConvertTo-Json -Depth 5

# 发送事件到 Event Grid 主题
$Headers = @{
    'aeg-sas-key' = $Keys.Key1
    'Content-Type' = 'application/json'
}

$Response = Invoke-RestMethod `
    -Uri "$($Topic.Endpoint)" `
    -Method Post `
    -Headers $Headers `
    -Body $EventPayload

Write-Host "事件已发布, ID: $EventId"

# --- 配置死信队列与重试策略 ---

# 更新订阅，添加死信队列和重试策略
$StorageAccountId = (Get-AzStorageAccount `
    -ResourceGroupName $ResourceGroup `
    -Name 'steventgriddead').Id
$DeadLetterDestination = @{
    endpointType = 'StorageBlob'
    properties = @{
        resourceId = $StorageAccountId
        blobContainerName = 'dead-letter-events'
    }
}

Set-AzEventGridSubscription `
    -EventSubscriptionName $SubscriptionName `
    -ResourceId $Topic.Id `
    -DeadLetterEndpoint "$StorageAccountId/blobServices/default/containers/dead-letter-events" `
    -MaxDeliveryAttempt 5 `
    -EventTtl 1440

Write-Host "死信队列和重试策略已配置"
Write-Host "最大投递尝试: 5 次, 事件存活时间: 1440 分钟"
```

执行结果示例：

```
事件已发布, ID: 3a7f2c1e-9b4d-4e8a-b6c3-1f2d3e4a5b6c
死信队列和重试策略已配置
最大投递尝试: 5 次, 事件存活时间: 1440 分钟
```

事件发布使用的是 Event Grid 的标准 REST 接口，需要通过主题密钥进行认证。生产环境中建议将密钥存储在 Azure Key Vault 中，通过 `Get-AzKeyVaultSecret` 动态获取，而不是硬编码在脚本里。死信队列（Dead Letter Queue）则确保了投递失败的事件不会丢失，方便后续排查和重放。

## 事件驱动自动化实战

掌握了基本的事件发布和订阅机制后，我们来构建一个完整的自动化场景：当 Azure 资源发生变更时，自动执行响应操作并记录审计日志。这个实战案例综合运用了 Event Grid 订阅、事件处理和自动化工作流编排。

```powershell
# --- 事件处理函数：接收并解析 Event Grid 事件 ---

function Receive-EventGridEvent {
    <#
    .SYNOPSIS
    处理 Event Grid Webhook 接收到的事件
    这是部署在 Azure Functions 或自托管 Web 服务中的处理逻辑
    #>

    param(
        [Parameter(Mandatory)]
        [object[]]$Events
    )

    foreach ($Event in $Events) {
        Write-Host "收到事件: $($Event.eventType)"
        Write-Host "  主题: $($Event.subject)"
        Write-Host "  时间: $($Event.eventTime)"

        switch ($Event.eventType) {
            'Ops.VM.Created' {
                Invoke-VmCreatedHandler -EventData $Event.data
            }
            'Ops.VM.Deleted' {
                Invoke-VmDeletedHandler -EventData $Event.data
            }
            'Ops.Storage.Uploaded' {
                Invoke-StorageUploadHandler -EventData $Event.data
            }
            default {
                Write-Warning "未处理的事件类型: $($Event.eventType)"
            }
        }
    }
}

# --- VM 创建事件处理器 ---

function Invoke-VmCreatedHandler {
    param([hashtable]$EventData)

    $VmName = $EventData.vmName
    $RgName = $EventData.resourceGroup

    Write-Host "处理 VM 创建事件: $VmName"

    # 1. 等待 VM 就绪
    $Timeout = 300
    $Start = Get-Date
    do {
        $Vm = Get-AzVM -ResourceGroupName $RgName -Name $VmName `
            -ErrorAction SilentlyContinue
        if ($Vm -and $Vm.ProvisioningState -eq 'Succeeded') { break }
        Start-Sleep -Seconds 10
    } while (((Get-Date) - $Start).TotalSeconds -lt $Timeout)

    # 2. 自动安装监控扩展
    Set-AzVMExtension `
        -ResourceGroupName $RgName `
        -VMName $VmName `
        -Name 'OMSExtension' `
        -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
        -ExtensionType 'MicrosoftMonitoringAgent' `
        -TypeHandlerVersion '1.0' `
        -Settings @{
            workspaceId = (Get-AzOperationalInsightsWorkspace `
                -ResourceGroupName 'rg-monitoring' `
                -Name 'law-production').CustomerId
        } `
        -ProtectedSettings @{
            workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKeys `
                -ResourceGroupName 'rg-monitoring' `
                -Name 'law-production').PrimarySharedKey
        } `
        -Location $Vm.Location

    # 3. 添加自动关机计划
    $ShutdownConfig = @{
        ResourceGroupName  = $RgName
        VMName             = $VmName
        Name               = 'auto-shutdown'
        ShutdownTime       = '19:00'
        TimeZone           = 'China Standard Time'
        NotificationStatus = 'Enabled'
        NotificationLocale = 'zh-CN'
    }
    # 使用 REST API 设置自动关机
    $ShutdownBody = @{
        properties = @{
            status = 'Enabled'
            taskType = 'ComputeVmShutdownTask'
            dailyRecurrence = @{ time = '19:00' }
            timeZoneId = 'China Standard Time'
            notificationSettings = @{
                status = 'Enabled'
                timeInMinutes = 30
                locale = 'zh-CN'
            }
        }
    } | ConvertTo-Json -Depth 3

    $VmResourceId = $Vm.Id
    $AutoShutdownUri = "https://management.azure.com$VmResourceId/providers/microsoft.devtestlab/schedules/auto-shutdown?api-version=2023-01-01"
    $Token = (Get-AzAccessToken).Token
    Invoke-AzRestMethod -Uri $AutoShutdownUri -Method Put -Payload $ShutdownBody `
        -Headers @{ Authorization = "Bearer $Token" } | Out-Null

    # 4. 记录审计日志
    $AuditEntry = @{
        Timestamp   = Get-Date -Format 'o'
        Operation   = 'VM.AutoConfigured'
        Resource    = "$RgName/$VmName"
        ConfiguredBy = 'EventGrid-Automation'
        Extensions  = @('OMSExtension')
        AutoShutdown = '19:00 CST'
    }
    $AuditEntry | ConvertTo-Json -Depth 3 | Out-File `
        -FilePath "/var/log/azure-audit/$(Get-Date -Format 'yyyyMMdd').json" `
        -Append -Encoding utf8

    Write-Host "VM $VmName 自动配置完成: 监控扩展已安装, 自动关机已设置"
}

# --- 辅助函数：发送告警通知 ---

function Send-OpsAlert {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet('Critical', 'Warning', 'Info')]
        [string]$Severity = 'Info'
    )

    $ColorMap = @{
        Critical = 'FF0000'
        Warning  = 'FFA500'
        Info     = '0078D4'
    }

    $Payload = @{
        title = $Title
        text  = $Message
        themeColor = $ColorMap[$Severity]
    } | ConvertTo-Json

    # 发送到 Teams Webhook（示例）
    $TeamsWebhook = Get-AzKeyVaultSecret `
        -VaultName 'kv-ops-secrets' `
        -Name 'TeamsAlertWebhook' `
        -AsPlainText

    Invoke-RestMethod -Uri $TeamsWebhook -Method Post `
        -Body $Payload -ContentType 'application/json'
}

# --- 查看事件投递指标 ---

$Metrics = Get-AzMetric `
    -ResourceId $Topic.Id `
    -MetricName 'Published Events', 'Delivered Events', 'Dropped Events', 'Dead Lettered Events' `
    -TimeGrain (New-TimeSpan -Hours 1) `
    -StartTime (Get-Date).AddHours(-24) `
    -EndTime (Get-Date)

$Metrics | ForEach-Object {
    $MetricName = $_.Name.Value
    $Total = ($_.Data | Measure-Object -Property Total -Sum).Sum
    Write-Host ("{0,-30} {1,10}" -f $MetricName, $Total)
}
```

执行结果示例：

```
收到事件: Ops.VM.Created
  主题: /operations/production/vm/web-01/critical
  时间: 2026-02-25T08:15:30.1234567Z
处理 VM 创建事件: web-01
VM web-01 自动配置完成: 监控扩展已安装, 自动关机已设置

Published Events                    1284
Delivered Events                    1281
Dropped Events                         0
Dead Lettered Events                   3
```

这个实战案例展示了完整的事件驱动自动化链路：当 Event Grid 推送 VM 创建事件后，处理脚本自动执行了四个步骤——等待 VM 就绪、安装监控扩展、配置自动关机、写入审计日志。通过 `Get-AzMetric` 还可以实时监控事件的投递健康度，及时发现投递异常。

## 注意事项

1. **Webhook 端点验证**：Event Grid 创建 Webhook 订阅时会发送验证握手请求（`ValidationCode`），你的端点必须在响应中返回该验证码，否则订阅创建会失败。建议在处理函数中优先处理 `Microsoft.EventGrid.SubscriptionValidationEvent` 事件类型。

2. **事件顺序与幂等性**：Event Grid 不保证事件的严格顺序，且在重试场景下可能重复投递。所有事件处理逻辑必须设计为幂等操作——通过事件 ID 去重是最常见的做法，可以将已处理的事件 ID 缓存在 Redis 或 Azure Cache 中。

3. **密钥安全管理**：Event Grid 主题的访问密钥等效于管理员权限，切勿硬编码在脚本中。生产环境应将密钥存入 Azure Key Vault，通过托管标识（Managed Identity）或服务主体访问，并定期轮换密钥。

4. **网络连通性**：如果 Webhook 端点部署在本地网络（非公网可达），需要使用 Azure Event Grid 的 Private Endpoint 功能，或改用事件中心（Event Hub）、服务总线（Service Bus）队列作为订阅端点，再由本地服务消费队列消息。

5. **重试与死信策略**：建议为所有事件订阅配置死信队列，设置合理的重试次数（推荐 5-10 次）和事件 TTL。死信队列中的事件应定期巡检，通过脚本批量重放或人工分析失败原因。

6. **成本控制**：Event Grid 按事件数量计费，自定义事件前务必使用事件过滤（`IncludedEventType`、`SubjectBeginsWith`、`SubjectEndsWith`、`AdvancedFilters`）精准订阅所需事件，避免接收大量无关事件导致不必要的费用支出。
