---
layout: post
date: 2025-09-19 08:00:00
title: "PowerShell 技能连载 - 消息队列与异步通信"
description: PowerTip of the Day - Message Queue and Async Communication in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- message-queue
- msmq
- async
---

_适用于 PowerShell 5.1 及以上版本_

在构建自动化运维系统时，不同组件之间的通信方式直接决定了系统的可靠性和扩展性。传统的同步调用方式要求调用方等待被调用方处理完毕后才能继续，这在高并发场景下容易成为瓶颈。消息队列（Message Queue）通过引入"发布-订阅"或"生产者-消费者"模式，让发送方和接收方解耦，从而实现真正意义上的异步通信。

Windows 平台原生提供了 MSMQ（Microsoft Message Queuing）服务，PowerShell 可以通过 .NET 类库直接与之交互。而在跨平台场景下，我们也可以借助文件系统、数据库或第三方消息中间件（如 RabbitMQ、Redis）来模拟队列行为。理解消息队列的核心概念（队列、消息、投递确认、死信）对设计健壮的自动化流程至关重要。

本文将从 MSMQ 原生队列操作入手，逐步扩展到基于文件系统的轻量队列实现，最后演示如何在 PowerShell 中构建一个完整的生产者-消费者模型，帮助你掌握异步通信的核心技巧。

## 使用 MSMQ 创建和操作消息队列

MSMQ 是 Windows 内置的消息队列服务，适合在 Windows 环境下构建可靠的异步通信管道。以下代码展示如何检测 MSMQ 服务状态、创建队列，以及发送和接收消息。

```powershell
# 检查 MSMQ 服务是否运行
$msmqService = Get-Service -Name 'MSMQ' -ErrorAction SilentlyContinue

if ($null -eq $msmqService) {
    Write-Warning 'MSMQ 服务未安装。请通过"启用或关闭 Windows 功能"安装 Message Queuing。'
    return
}

if ($msmqService.Status -ne 'Running') {
    Write-Host '正在启动 MSMQ 服务...'
    Start-Service -Name 'MSMQ'
}

# 加载 MSMQ 的 .NET 程序集
Add-Type -AssemblyName 'System.Messaging'

# 创建私有队列（如果不存在）
$queuePath = '.\Private$\PowerShellTaskQueue'

if (-not [System.Messaging.MessageQueue]::Exists($queuePath)) {
    $queue = [System.Messaging.MessageQueue]::Create($queuePath)
    Write-Host "队列已创建：$queuePath"
} else {
    $queue = New-Object System.Messaging.MessageQueue($queuePath)
    Write-Host "队列已存在，直接连接：$queuePath"
}

# 发送消息到队列
$taskMessage = @{
    TaskId    = [guid]::NewGuid().ToString()
    TaskName  = 'BackupDatabase'
    CreatedAt = (Get-Date).ToString('o')
    Payload   = @{ Database = 'ProductionDB'; Destination = '\\backup\db\' }
} | ConvertTo-Json -Depth 5

$msg = New-Object System.Messaging.Message
$msg.Body = $taskMessage
$msg.Label = 'DBBackupTask'
$msg.Priority = [System.Messaging.MessagePriority]::High

$queue.Send($msg)
Write-Host '消息已发送到队列。'

# 从队列接收消息
$queue.Formatter = New-Object System.Messaging.XmlMessageFormatter(
    @([string])
)

$receivedMsg = $queue.Receive(
    [System.TimeSpan]::FromSeconds(5)
)

$receivedBody = $receivedMsg.Body
$receivedLabel = $receivedMsg.Label

Write-Host "收到消息 - 标签: $receivedLabel"
Write-Host "消息内容: $receivedBody"
```

执行结果示例：

```
正在启动 MSMQ 服务...
队列已创建：.\Private$\PowerShellTaskQueue
消息已发送到队列。
收到消息 - 标签: DBBackupTask
消息内容: {
    "TaskId":  "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "TaskName":  "BackupDatabase",
    "CreatedAt":  "2025-09-19T08:30:00.0000000+08:00",
    "Payload":  {
        "Database":  "ProductionDB",
        "Destination":  "\\\\backup\\db\\"
    }
}
```

## 基于文件系统的轻量级消息队列

并非所有环境都安装了 MSMQ，尤其在跨平台场景（Linux、macOS）下更是如此。我们可以用文件系统模拟消息队列的核心行为：将消息写入独立文件实现入队，读取并删除文件实现出队。这种方案简单可靠，适合中小规模的自动化任务。

```powershell
# 定义文件队列的基础路径
$queueRoot = Join-Path $env:TEMP 'PSFileQueue'

# 初始化队列目录结构
$directories = @(
    (Join-Path $queueRoot 'pending')
    (Join-Path $queueRoot 'processing')
    (Join-Path $queueRoot 'completed')
    (Join-Path $queueRoot 'deadletter')
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "已创建目录: $dir"
    }
}

# 定义入队函数
function Send-FileQueueMessage {
    param(
        [Parameter(Mandatory)]
        [string]$QueuePath,

        [Parameter(Mandatory)]
        [hashtable]$MessageData,

        [string]$Label = 'Default'
    )

    $messageId = [guid]::NewGuid().ToString('N')
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-ffff'

    $envelope = @{
        MessageId   = $messageId
        Label       = $Label
        CreatedAt   = (Get-Date).ToString('o')
        RetryCount  = 0
        MaxRetries  = 3
        Data        = $MessageData
    }

    $fileName = '{0}_{1}.json' -f $timestamp, $messageId.Substring(0, 8)
    $filePath = Join-Path (Join-Path $QueuePath 'pending') $fileName

    $envelope | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Encoding UTF8

    Write-Host "消息已入队: $fileName (Label: $Label)"
    return $messageId
}

# 定义出队函数
function Receive-FileQueueMessage {
    param(
        [Parameter(Mandatory)]
        [string]$QueuePath,

        [int]$VisibilityTimeout = 30
    )

    $pendingDir = Join-Path $QueuePath 'pending'
    $processingDir = Join-Path $QueuePath 'processing'

    $files = Get-ChildItem -Path $pendingDir -Filter '*.json' |
        Sort-Object Name |
        Select-Object -First 1

    if ($null -eq $files) {
        Write-Host '队列为空，没有待处理的消息。'
        return $null
    }

    $file = $files
    $destPath = Join-Path $processingDir $file.Name

    # 原子性移动：从 pending 到 processing
    Move-Item -Path $file.FullName -Destination $destPath -Force

    $message = Get-Content $destPath -Raw | ConvertFrom-Json

    Write-Host "消息已出队: $($file.Name) (ID: $($message.MessageId))"
    return [PSCustomObject]@{
        FilePath = $destPath
        Message  = $message
    }
}

# 测试：发送 3 条消息
$testMessages = @(
    @{ Server = 'SRV01'; Action = 'RestartService'; Service = 'Spooler' }
    @{ Server = 'SRV02'; Action = 'ClearLogs'; LogName = 'Application' }
    @{ Server = 'SRV03'; Action = 'CheckDisk'; Drive = 'C:' }
)

foreach ($msg in $testMessages) {
    Send-FileQueueMessage -QueuePath $queueRoot -MessageData $msg -Label 'Maintenance'
}

# 测试：接收一条消息
$received = Receive-FileQueueMessage -QueuePath $queueRoot
```

执行结果示例：

```
已创建目录: /tmp/PSFileQueue/pending
已创建目录: /tmp/PSFileQueue/processing
已创建目录: /tmp/PSFileQueue/completed
已创建目录: /tmp/PSFileQueue/deadletter
消息已入队: 20250919-0830001234_a1b2c3d4.json (Label: Maintenance)
消息已入队: 20250919-0830001235_e5f6a7b8.json (Label: Maintenance)
消息已入队: 20250919-0830001236_c9d0e1f2.json (Label: Maintenance)
消息已出队: 20250919-0830001234_a1b2c3d4.json (ID: a1b2c3d4e5f6...)
```

## 构建生产者-消费者异步处理模型

有了队列基础设施后，我们需要一个完整的生产者-消费者模型来驱动异步处理。以下代码使用 PowerShell 后台作业（Job）模拟并发消费者，实现消息的并行处理，并包含重试和死信机制。

```powershell
# 消费者处理逻辑
function Invoke-QueueConsumer {
    param(
        [string]$QueuePath,
        [int]$ConsumerId,
        [int]$PollIntervalSeconds = 2
    )

    $pendingDir = Join-Path $QueuePath 'pending'
    $processingDir = Join-Path $QueuePath 'processing'
    $completedDir = Join-Path $QueuePath 'completed'
    $deadletterDir = Join-Path $QueuePath 'deadletter'

    $processed = 0

    # 持续轮询，最多处理 5 条消息作为演示
    while ($processed -lt 5) {
        $files = Get-ChildItem -Path $pendingDir -Filter '*.json' |
            Sort-Object Name |
            Select-Object -First 1

        if ($null -eq $files) {
            Write-Host "[消费者 $ConsumerId] 队列为空，等待 ${PollIntervalSeconds}s..."
            Start-Sleep -Seconds $PollIntervalSeconds
            continue
        }

        $file = $files
        $destPath = Join-Path $processingDir $file.Name

        try {
            Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
            $message = Get-Content $destPath -Raw | ConvertFrom-Json

            Write-Host "[消费者 $ConsumerId] 正在处理: $($message.Label) " `
                "- ID: $($message.MessageId.Substring(0,8))..."

            # 模拟处理耗时
            $workTime = Get-Random -Minimum 500 -Maximum 2000
            Start-Sleep -Milliseconds $workTime

            # 模拟偶发失败（约 20% 概率）
            $shouldFail = (Get-Random -Minimum 1 -Maximum 100) -le 20

            if ($shouldFail) {
                throw '模拟的处理异常'
            }

            # 处理成功：移到 completed
            $completedPath = Join-Path $completedDir $file.Name
            Move-Item -Path $destPath -Destination $completedPath -Force

            $processed++
            Write-Host "[消费者 $ConsumerId] 处理完成 " `
                "(耗时 ${workTime}ms, 累计 $processed 条)"
        } catch {
            Write-Warning "[消费者 $ConsumerId] 处理失败: $_"

            # 重试逻辑
            $message = Get-Content $destPath -Raw | ConvertFrom-Json
            $retryCount = $message.RetryCount + 1

            if ($retryCount -ge $message.MaxRetries) {
                # 超过最大重试次数，移入死信队列
                $deadPath = Join-Path $deadletterDir $file.Name
                Move-Item -Path $destPath -Destination $deadPath -Force
                Write-Warning "[消费者 $ConsumerId] 消息移入死信队列: $($file.Name)"
            } else {
                # 更新重试计数后放回 pending
                $message.RetryCount = $retryCount
                $message | ConvertTo-Json -Depth 10 |
                    Set-Content -Path $destPath -Encoding UTF8

                $retryPath = Join-Path $pendingDir $file.Name
                Move-Item -Path $destPath -Destination $retryPath -Force
                Write-Host "[消费者 $ConsumerId] 消息已放回队列 " `
                    "(重试 $retryCount/$($message.MaxRetries))"
            }

            Start-Sleep -Seconds 1
        }
    }

    return $processed
}

# 先往队列灌入一批消息
$queueRoot = Join-Path $env:TEMP 'PSFileQueue'

$tasks = @(
    @{ Task = 'CleanupTemp'; Path = 'C:\Temp' }
    @{ Task = 'ArchiveLogs'; Path = 'C:\Logs' }
    @{ Task = 'SyncData'; Source = '\\server\share'; Dest = 'D:\Backup' }
    @{ Task = 'HealthCheck'; Server = 'db-prod-01' }
    @{ Task = 'UpdateConfig'; App = 'WebApp'; Version = '2.5.0' }
    @{ Task = 'RotateKeys'; Service = 'APIGateway' }
    @{ Task = 'SendReport'; Recipients = @('admin@corp.com') }
    @{ Task = 'ValidateBackup'; Location = '\\nas\backup' }
)

foreach ($task in $tasks) {
    Send-FileQueueMessage -QueuePath $queueRoot -MessageData $task -Label 'BatchJob'
}

Write-Host "`n启动 3 个并行消费者...`n"

# 启动 3 个消费者作为后台作业
$jobs = @()
foreach ($i in 1..3) {
    $jobs += Start-Job -ScriptBlock {
        param($QueuePath, $ConsumerId)
        # 在 Job 中重新定义必要的函数逻辑
        $pendingDir = Join-Path $QueuePath 'pending'
        $processingDir = Join-Path $QueuePath 'processing'
        $completedDir = Join-Path $QueuePath 'completed'
        $deadletterDir = Join-Path $QueuePath 'deadletter'

        $count = 0
        while ($count -lt 3) {
            $files = Get-ChildItem -Path $pendingDir -Filter '*.json' |
                Sort-Object Name |
                Select-Object -First 1

            if ($null -eq $files) {
                Start-Sleep -Seconds 1
                continue
            }

            $file = $files
            $dest = Join-Path $processingDir $file.Name

            try {
                Move-Item $file.FullName $dest -Force -ErrorAction Stop
                $msg = Get-Content $dest -Raw | ConvertFrom-Json
                $workMs = Get-Random -Min 200 -Max 1000
                Start-Sleep -Milliseconds $workMs
                $done = Join-Path $completedDir $file.Name
                Move-Item $dest $done -Force
                $count++
                "[$ConsumerId] 完成: $($msg.Label) - $($msg.Data.Task)"
            } catch {
                $dead = Join-Path $deadletterDir $file.Name
                if (Test-Path $dest) { Move-Item $dest $dead -Force -ErrorAction SilentlyContinue }
                "[$ConsumerId] 失败: $($file.Name)"
            }
        }
        return $count
    } -ArgumentList $queueRoot, $i
}

# 等待所有作业完成
$results = $jobs | Wait-Job -Timeout 60 | Receive-Job

# 清理作业
$jobs | Remove-Job -Force

Write-Host "`n=== 消费结果汇总 ==="
foreach ($result in $results) {
    Write-Host $result
}

# 查看队列最终状态
Write-Host "`n=== 队列最终状态 ==="
foreach ($dir in @('pending', 'processing', 'completed', 'deadletter')) {
    $count = (Get-ChildItem (Join-Path $queueRoot $dir) -Filter '*.json' -ErrorAction SilentlyContinue).Count
    Write-Host ("{0,-15} {1} 条消息" -f $dir, $count)
}
```

执行结果示例：

```
启动 3 个并行消费者...

=== 消费结果汇总 ===
[1] 完成: BatchJob - CleanupTemp
[2] 完成: BatchJob - ArchiveLogs
[3] 完成: BatchJob - SyncData
[1] 完成: BatchJob - HealthCheck
[2] 完成: BatchJob - UpdateConfig
[3] 完成: BatchJob - RotateKeys

=== 队列最终状态 ===
pending         0 条消息
processing      0 条消息
completed       6 条消息
deadletter      2 条消息
```

## 注意事项

1. **MSMQ 可用性限制**：MSMQ 仅在 Windows 平台可用，且需要在"启用或关闭 Windows 功能"中手动安装。如果你的自动化流程需要跨平台运行（Linux、macOS），建议使用文件队列或第三方消息中间件（如 RabbitMQ、Redis Streams）作为替代方案。

2. **文件队列的原子性**：使用文件系统模拟队列时，`Move-Item` 操作在 NTFS 和大多数 Linux 文件系统上是原子的，这是确保同一消息不会被多个消费者同时取走的关键。但在网络共享路径（UNC 路径）上，原子性可能无法保证，需要额外加锁机制。

3. **消息大小与性能**：MSMQ 单条消息默认大小限制为 4MB。如果需要传输更大的数据负载，应将数据存储在外部（如文件共享、数据库、对象存储），在消息体中只传递引用路径。文件队列虽然没有硬性大小限制，但过大的 JSON 文件会显著影响读写性能。

4. **死信队列不可忽略**：任何消息队列系统都必须有死信（Dead Letter）处理机制。超过最大重试次数的消息不应被简单丢弃，而应移入死信队列供人工审查或定时重处理。定期监控死信队列的积压情况是运维健康度的重要指标。

5. **后台作业的生命周期管理**：使用 `Start-Job` 启动消费者时，务必通过 `Wait-Job` 设置超时时间，并在完成后调用 `Remove-Job` 清理资源。长时间运行的消费者建议改用 .NET 的 `System.Threading.Thread` 或 `Runspace` 池，以获得更好的性能和更精细的控制。

6. **幂等性设计**：消费者处理逻辑必须设计为幂等（Idempotent），即同一条消息被处理多次不会产生副作用。这是因为即使在最佳实践的队列系统中，"至少一次投递"（at-least-once delivery）也是比"恰好一次投递"（exactly-once delivery）更容易实现的保证。在代码中通过检查 `MessageId` 和处理状态来跳过已处理过的消息是常见的幂等策略。
