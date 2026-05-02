---
layout: post
date: 2025-09-26 08:00:00
updated: 2025-09-26 08:00:00
title: "PowerShell 技能连载 - Webhook 集成"
description: PowerTip of the Day - Webhook Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- webhook
- integration
- notification
- teams
---

_适用于 PowerShell 5.1 及以上版本_

Webhook 是现代系统中实现事件驱动通知的主流方式。无论是 CI/CD 流水线的构建结果、监控系统的告警事件，还是业务系统的关键操作日志，都可以通过 Webhook 推送到指定端点。借助 PowerShell 的 `Invoke-RestMethod` 和 `Invoke-WebRequest`，我们可以非常方便地向各类平台发送 Webhook 通知，无需安装额外的 SDK。

在企业环境中，团队沟通工具（如 Microsoft Teams、Slack、钉钉）普遍支持 Incoming Webhook。运维和开发人员常常需要在脚本执行完毕后自动发送通知，例如部署成功、备份完成、磁盘空间不足等场景。将这些通知流程封装成可复用的 PowerShell 函数，不仅提高工作效率，还能确保团队及时获知系统状态变化。

本文将从基础概念出发，逐步介绍如何使用 PowerShell 发送 Webhook 请求，包括消息格式化、错误处理、重试机制，以及如何构建一个通用的 Webhook 通知模块，适配多个目标平台。

<!-- more -->

## 发送简单的 Webhook 请求

最基础的 Webhook 调用就是向指定 URL 发送一个 HTTP POST 请求。大多数平台的 Incoming Webhook 端点都接受 JSON 格式的消息体。以下示例展示了如何向 Microsoft Teams 的 Webhook 地址发送一条简单的文本通知。

```powershell
# 定义 Teams Webhook 地址
$webhookUrl = "https://outlook.office.com/webhook/your-webhook-url-here"

# 构造消息体
$messageBody = @{
    text = "部署已完成：生产环境更新至 v2.5.0 版本。"
} | ConvertTo-Json -Depth 3

# 发送 Webhook 请求
$response = Invoke-RestMethod `
    -Uri $webhookUrl `
    -Method Post `
    -Body $messageBody `
    -ContentType "application/json; charset=utf-8"

Write-Host "Webhook 发送状态：$response"
```

执行结果示例：

```text
Webhook 发送状态：1
```

返回值 `1` 表示 Teams 成功接收了消息。不同平台的响应格式不同，有的返回 HTTP 状态码，有的返回 JSON 对象，需要根据具体平台的文档来判断是否发送成功。

## 发送带格式的 Adaptive Card 消息

简单的纯文本消息信息量有限。Microsoft Teams 支持 Adaptive Card 格式，可以在消息中嵌入标题、颜色标记、事实列表等结构化内容，让通知更加直观易读。下面展示了如何构造一个包含部署详情的 Adaptive Card 消息。

```powershell
# 定义 Teams Webhook 地址
$webhookUrl = "https://outlook.office.com/webhook/your-webhook-url-here"

# 构造 Adaptive Card 消息
$cardPayload = @{
    type    = "message"
    attachments = @(
        @{
            contentType = "application/vnd.microsoft.card.adaptive"
            content     = @{
                type    = "AdaptiveCard"
                version = "1.4"
                body    = @(
                    @{
                        type  = "TextBlock"
                        text  = "部署通知"
                        size  = "Large"
                        weight = "Bolder"
                        color = "Accent"
                    }
                    @{
                        type   = "FactSet"
                        facts  = @(
                            @{ title = "环境"; value = "Production" }
                            @{ title = "版本"; value = "v2.5.0" }
                            @{ title = "操作人"; value = "admin@vichamp.com" }
                            @{ title = "状态"; value = "成功" }
                            @{ title = "耗时"; value = "3m 42s" }
                        )
                    }
                )
                actions = @(
                    @{
                        type = "Action.OpenUrl"
                        title = "查看构建日志"
                        url  = "https://ci.vichamp.com/build/1024"
                    }
                )
            }
        }
    )
} | ConvertTo-Json -Depth 10

# 发送请求
$response = Invoke-RestMethod `
    -Uri $webhookUrl `
    -Method Post `
    -Body ([System.Text.Encoding]::UTF8.GetBytes($cardPayload)) `
    -ContentType "application/json; charset=utf-8"

Write-Host "卡片消息已发送，响应：$response"
```

执行结果示例：

```text
卡片消息已发送，响应：1
```

注意这里使用了 `[System.Text.Encoding]::UTF8.GetBytes()` 对消息体进行编码，确保中文字符在传输过程中不会出现乱码。Adaptive Card 的结构相对复杂，建议先在 Adaptive Card Designer（微软官方提供的在线设计器）中调试好布局，再将 JSON 结构移植到 PowerShell 脚本中。

## 构建通用 Webhook 通知模块

在实际工作中，我们通常需要向多个平台发送不同类型的通知。把 Webhook 调用封装成一个通用模块，支持重试机制、超时控制和日志记录，能够大幅提升代码的可维护性。以下是一个完整的通用通知模块示例。

```powershell
# 通用 Webhook 配置
$webhookConfig = @{
    Teams    = "https://outlook.office.com/webhook/teams-url"
    DingTalk = "https://oapi.dingtalk.com/robot/send?access_token=your-token"
    Slack    = "https://hooks.slack.com/services/your/slack/webhook"
}

# 通用 Webhook 发送函数
function Send-WebhookNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Payload,

        [Parameter(Mandatory)]
        [string]$Platform,

        [int]$MaxRetries = 3,

        [int]$TimeoutSeconds = 30
    )

    # 验证平台是否在配置中
    if (-not $webhookConfig.ContainsKey($Platform)) {
        Write-Error "不支持的平台：$Platform。支持的平台：$($webhookConfig.Keys -join ', ')"
        return
    }

    $targetUrl = $webhookConfig[$Platform]
    $jsonBody = $Payload | ConvertTo-Json -Depth 10
    $byteBody = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)

    $attempt = 0
    $success = $false

    while ($attempt -lt $MaxRetries -and -not $success) {
        $attempt++
        try {
            Write-Host "第 $attempt 次尝试发送 Webhook 到 $Platform..."

            $response = Invoke-RestMethod `
                -Uri $targetUrl `
                -Method Post `
                -Body $byteBody `
                -ContentType "application/json; charset=utf-8" `
                -TimeoutSec $TimeoutSeconds `
                -ErrorAction Stop

            $success = $true
            Write-Host "Webhook 发送成功（平台：$Platform，尝试次数：$attempt）"

            # 记录发送日志
            $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | SENT | Platform=$Platform | Attempts=$attempt"
            Add-Content -Path "webhook-notifications.log" -Value $logEntry

            return $response
        }
        catch {
            $errorMsg = $_.Exception.Message
            Write-Warning "第 $attempt 次发送失败：$errorMsg"

            if ($attempt -lt $MaxRetries) {
                $waitSeconds = [math]::Pow(2, $attempt)
                Write-Host "等待 ${waitSeconds} 秒后重试..."
                Start-Sleep -Seconds $waitSeconds
            }
        }
    }

    if (-not $success) {
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FAILED | Platform=$Platform | Attempts=$MaxRetries"
        Add-Content -Path "webhook-notifications.log" -Value $logEntry
        Write-Error "Webhook 发送失败，已重试 $MaxRetries 次（平台：$Platform）"
    }
}

# 批量向多个平台发送通知
$platforms = @("Teams", "DingTalk")

foreach ($platform in $platforms) {
    # 根据不同平台构造对应的消息格式
    $payload = switch ($platform) {
        "Teams" {
            @{
                text = "[告警] 服务器 SRV-01 CPU 使用率超过 90%，请及时检查。"
            }
        }
        "DingTalk" {
            @{
                msgtype = "text"
                text    = @{
                    content = "[告警] 服务器 SRV-01 CPU 使用率超过 90%，请及时检查。"
                }
            }
        }
        default {
            @{ text = "[告警] 服务器 SRV-01 CPU 使用率超过 90%" }
        }
    }

    Send-WebhookNotification -Payload $payload -Platform $platform -MaxRetries 3 -TimeoutSeconds 15
}
```

执行结果示例：

```text
第 1 次尝试发送 Webhook 到 Teams...
Webhook 发送成功（平台：Teams，尝试次数：1）
第 1 次尝试发送 Webhook 到 DingTalk...
Webhook 发送成功（平台：DingTalk，尝试次数：1）
```

这个模块的核心设计要点包括：配置与逻辑分离，将各平台的 Webhook 地址集中管理；指数退避重试策略，在遇到网络抖动时自动等待并重试；统一的日志记录，所有发送结果都会追加到日志文件中，便于后续排查。

## 监听 Webhook 回调（简易 HTTP 服务器）

除了主动发送 Webhook，有时候还需要在本地搭建一个 HTTP 端点来接收其他系统推送过来的 Webhook 回调。PowerShell 可以通过 .NET 的 `HttpListener` 类快速实现一个简易的 Webhook 接收服务器。

```powershell
# 创建 HTTP 监听器
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8080/webhook/")

try {
    $listener.Start()
    Write-Host "Webhook 监听器已启动：http://localhost:8080/webhook/"
    Write-Host "按 Ctrl+C 停止监听..."

    # 持续监听请求
    while ($listener.IsListening) {
        # 异步等待请求（设置超时以便可以正常退出）
        $contextTask = $listener.GetContextAsync()

        # 等待请求到达（每秒检查一次是否还在监听）
        while (-not $contextTask.AsyncWaitHandle.WaitOne(1000)) {
            # 此处可加入退出条件的检查
        }

        $context = $contextTask.GetAwaiter().GetResult()
        $request = $context.Request

        # 读取请求体
        $reader = [System.IO.StreamReader]::new($request.InputStream)
        $requestBody = $reader.ReadToEnd()
        $reader.Close()

        Write-Host "`n收到 Webhook 请求："
        Write-Host "  时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Host "  方法：$($request.HttpMethod)"
        Write-Host "  路径：$($request.Url.AbsolutePath)"
        Write-Host "  内容：$requestBody"

        # 解析 JSON 内容
        try {
            $payload = $requestBody | ConvertFrom-Json
            Write-Host "  事件类型：$($payload.event_type)"
            Write-Host "  触发来源：$($payload.source)"
        }
        catch {
            Write-Host "  （无法解析 JSON 内容）"
        }

        # 返回 HTTP 200 响应
        $response = $context.Response
        $response.StatusCode = 200
        $responseContent = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok"}')
        $response.ContentLength64 = $responseContent.Length
        $response.OutputStream.Write($responseContent, 0, $responseContent.Length)
        $response.OutputStream.Close()

        Write-Host "  已返回 200 OK"
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Webhook 监听器已停止。"
}
```

执行结果示例：

```text
Webhook 监听器已启动：http://localhost:8080/webhook/
按 Ctrl+C 停止监听...

收到 Webhook 请求：
  时间：2025-09-26 10:30:15
  方法：POST
  路径：/webhook/
  内容：{"event_type":"deploy.complete","source":"ci-pipeline","version":"v2.5.0"}
  事件类型：deploy.complete
  触发来源：ci-pipeline
  已返回 200 OK
```

这个简易监听器适合在开发和调试阶段使用。如果需要在生产环境中长期运行，建议使用 Azure Functions 或 AWS Lambda 等无服务器架构来接收 Webhook，这样可以获得更好的可靠性和可扩展性。

## 结合 CI/CD 的 Webhook 通知实战

下面展示一个更贴近真实场景的例子：在 CI/CD 脚本中，根据构建结果动态决定通知内容和接收人，并发送带有状态标记的富文本消息。

```powershell
# 模拟 CI/CD 构建结果
$buildResult = @{
    PipelineName = "main-deploy"
    BuildNumber  = "2025.09.26.1"
    Branch       = "main"
    Commit       = "a1b2c3d"
    Status       = "succeeded"
    Duration     = "5m 18s"
    TriggeredBy  = "victorwoo"
    Artifacts    = @("app-v2.5.0.zip", "docs-v2.5.0.pdf")
}

# 根据构建状态选择颜色和图标
$colorMap = @{
    succeeded = "Good"
    failed    = "Attention"
    cancelled = "Warning"
}

$statusIcon = switch ($buildResult.Status) {
    "succeeded" { "[PASS]" }
    "failed"    { "[FAIL]" }
    "cancelled" { "[SKIP]" }
    default     { "[????]" }
}

$cardColor = $colorMap[$buildResult.Status]
$artifactsList = $buildResult.Artifacts -join ", "

# 构造通知消息的文本内容
$notificationText = @(
    "$statusIcon 构建 $($buildResult.Status.ToUpper())"
    ""
    "流水线：$($buildResult.PipelineName)"
    "构建号：$($buildResult.BuildNumber)"
    "分支：$($buildResult.Branch) ($($buildResult.Commit))"
    "触发人：$($buildResult.TriggeredBy)"
    "耗时：$($buildResult.Duration)"
    "产物：$artifactsList"
) -join "`n"

Write-Host $notificationText
```

执行结果示例：

```text
[PASS] 构建 SUCCEEDED

流水线：main-deploy
构建号：2025.09.26.1
分支：main (a1b2c3d)
触发人：victorwoo
耗时：5m 18s
产物：app-v2.5.0.zip, docs-v2.5.0.pdf
```

将上述构建结果整合到 Webhook 发送流程中，即可实现自动化的构建状态通知。团队每次提交代码后，无需手动查看 CI 面板，就能在即时通讯工具中第一时间收到构建结果。

## 注意事项

1. **保护 Webhook 地址安全**：Webhook URL 本质上是一个认证令牌，切勿将其硬编码在脚本中提交到代码仓库。推荐使用环境变量或 Azure Key Vault 等密钥管理服务来存储，例如 `$env:TEAMS_WEBHOOK_URL`。

2. **注意消息体编码**：当消息内容包含中文字符时，务必使用 UTF-8 编码发送。直接传递字符串可能导致中文乱码，建议使用 `[System.Text.Encoding]::UTF8.GetBytes()` 方法将 JSON 转换为字节数组后再发送。

3. **实现重试与退避机制**：网络请求可能因瞬时故障失败，建议实现指数退避重试策略（Exponential Backoff）。首次重试等待 2 秒，第二次 4 秒，第三次 8 秒，以此类推。同时设置最大重试次数，避免无限循环。

4. **关注各平台的消息格式差异**：Microsoft Teams 使用 Adaptive Card 或简单文本格式，钉钉支持 text、markdown、actionCard 等消息类型，Slack 使用 Block Kit。向不同平台发送消息时，需要根据其 API 文档构造对应的消息结构，不可混用。

5. **设置合理的超时时间**：Webhook 请求应当设置超时时间（推荐 15-30 秒），避免因目标服务无响应而导致脚本长时间挂起。使用 `Invoke-RestMethod` 的 `-TimeoutSec` 参数可以方便地控制请求超时。

6. **做好日志记录和审计**：每次 Webhook 发送操作都应记录日志，包括发送时间、目标平台、请求内容摘要、响应状态和重试次数。这不仅有助于故障排查，也是运维审计的重要依据。建议将日志写入文件并定期归档。
