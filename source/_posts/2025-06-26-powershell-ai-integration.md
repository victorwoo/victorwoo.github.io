---
layout: post
date: 2025-06-26 08:00:00
updated: 2025-06-26 08:00:00
title: "PowerShell 技能连载 - AI 服务集成"
description: PowerTip of the Day - AI Service Integration in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
- llm
- openai
- ollama
---

_适用于 PowerShell 5.1 及以上版本，调用 AI API 需要网络访问和 API 密钥_

2025 年，大语言模型（LLM）已经从实验性工具变成了生产力基础设施的一部分。PowerShell 作为自动化运维的核心语言，可以很自然地与 AI 服务集成——用自然语言生成运维脚本、让 AI 分析日志错误、构建智能告警系统、甚至搭建本地的 AI 助手。无论是调用云端 API（OpenAI、Azure OpenAI）还是本地模型（Ollama），PowerShell 都能胜任。

本文将讲解如何在 PowerShell 中调用 AI 服务、处理响应流，以及构建实用的 AI 驱动运维工具。

<!-- more -->

## 调用 OpenAI API

```powershell
function Invoke-OpenAIChat {
    <#
    .SYNOPSIS
    调用 OpenAI Chat Completion API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$SystemPrompt = "你是一个 PowerShell 运维专家，回答简洁准确。",

        [string]$Model = "gpt-4o-mini",

        [int]$MaxTokens = 2048,

        [double]$Temperature = 0.3
    )

    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        throw "请设置环境变量 OPENAI_API_KEY"
    }

    $body = @{
        model       = $Model
        messages    = @(
            @{ role = "system"; content = $SystemPrompt },
            @{ role = "user";   content = $Prompt }
        )
        max_tokens  = $MaxTokens
        temperature = $Temperature
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
        -Method Post `
        -Headers @{ "Authorization" = "Bearer $apiKey" } `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    return $response.choices[0].message.content
}

# 示例：让 AI 分析错误日志
$errorLog = Get-Content "C:\Logs\app-error.log" -Tail 20 -ErrorAction SilentlyContinue
if ($errorLog) {
    $analysis = Invoke-OpenAIChat -Prompt "分析以下错误日志，找出根本原因并给出修复建议：`n$($errorLog -join "`n")"
    Write-Host $analysis -ForegroundColor Cyan
}

# 示例：生成 PowerShell 脚本
$script = Invoke-OpenAIChat -Prompt "写一个 PowerShell 脚本：监控指定目录的磁盘空间，低于阈值时发送邮件告警" -Temperature 0.2
Write-Host $script
```

执行结果示例：

```
根据日志分析，根本原因是数据库连接池耗尽：
1. 错误 "Timeout expired" 在 14:30-14:45 期间集中出现
2. 连接池大小设置为 100，但并发请求峰值达到 200+

修复建议：
1. 增大连接池大小到 Max Pool Size=200
2. 添加连接超时重试逻辑
3. 检查是否有未正确关闭的数据库连接
```

## 调用本地 Ollama 模型

对于内网环境或数据敏感场景，可以使用 Ollama 在本地运行模型：

```powershell
function Invoke-OllamaChat {
    <#
    .SYNOPSIS
    调用本地 Ollama API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Model = "llama3.2",

        [string]$BaseUrl = "http://localhost:11434",

        [switch]$Stream
    )

    $body = @{
        model  = $Model
        prompt = $Prompt
        stream = $Stream.IsPresent
    } | ConvertTo-Json

    if ($Stream) {
        # 流式输出
        $response = Invoke-WebRequest -Uri "$BaseUrl/api/generate" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body `
            -UseBasicParsing

        $lines = $response.Content -split "`n" | Where-Object { $_.Trim() }
        foreach ($line in $lines) {
            $json = $line | ConvertFrom-Json
            Write-Host $json.response -NoNewline
        }
        Write-Host
    } else {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/generate" `
            -Method Post `
            -ContentType "application/json" `
            -Body $body

        return $response.response
    }
}

# 先检查 Ollama 是否运行
try {
    $models = Invoke-RestMethod -Uri "http://localhost:11434/api/tags"
    Write-Host "Ollama 可用模型：" -ForegroundColor Green
    $models.models | ForEach-Object { Write-Host "  - $($_.name) ($($_.size / 1GB -as [int]) GB)" }
} catch {
    Write-Host "Ollama 未运行，请先启动：ollama serve" -ForegroundColor Yellow
}

# 本地 AI 分析
$result = Invoke-OllamaChat -Prompt "解释以下 PowerShell 命令的作用：Get-ChildItem | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } | Sort-Object Length -Descending | Select-Object -First 10"
Write-Host $result
```

执行结果示例：

```
Ollama 可用模型：
  - llama3.2:latest (2 GB)
  - qwen2.5-coder:7b (4 GB)
这个命令查找当前目录下最近 7 天内修改过的文件，按文件大小降序排列，显示最大的 10 个文件。
```

## AI 驱动的智能告警

结合 AI 和监控数据，构建智能告警系统：

```powershell
function Send-SmartAlert {
    <#
    .SYNOPSIS
    AI 增强的智能告警
    #>
    [CmdletBinding()]
    param(
        [string]$MetricName,
        [double]$CurrentValue,
        [double]$Threshold,
        [string]$Context
    )

    $severity = if ($CurrentValue -gt $Threshold * 2) { "严重" } elseif ($CurrentValue -gt $Threshold) { "警告" } else { "正常" }

    if ($severity -eq "正常") { return }

    $prompt = @"
运维告警信息：
- 指标：$MetricName
- 当前值：$CurrentValue
- 阈值：$Threshold
- 严重程度：$severity
- 上下文：$Context

请简要分析可能的原因，并给出 2-3 条排查建议。回复用中文，不超过 200 字。
"@

    try {
        $aiAdvice = Invoke-OllamaChat -Model "llama3.2" -Prompt $prompt
    } catch {
        $aiAdvice = "AI 分析不可用，请人工排查。"
    }

    $alertMsg = @"
[$severity] $MetricName 告警
当前值：$CurrentValue（阈值：$Threshold）

AI 分析：
$aiAdvice

时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

    Write-Host $alertMsg -ForegroundColor $(if ($severity -eq "严重") { "Red" } else { "Yellow" })

    return $alertMsg
}

# 监控磁盘空间
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$usedPct = [math]::Round(($disk.Size - $disk.FreeSpace) / $disk.Size * 100, 1)

Send-SmartAlert -MetricName "C盘使用率" -CurrentValue $usedPct -Threshold 80 `
    -Context "文件服务器，主要存放日志和备份文件"
```

执行结果示例：

```
[警告] C盘使用率 告警
当前值：85.3（阈值：80）

AI 分析：
可能原因：日志文件积累、备份文件未清理。
排查建议：
1. 检查 C:\Logs 目录下的日志文件大小
2. 清理超过 30 天的旧日志
3. 检查 Windows Update 缓存：Dism /Online /Cleanup-Image /StartComponentCleanup

时间：2025-06-26 10:30:15
```

## 批量 AI 处理

利用 AI 批量处理运维任务：

```powershell
function Invoke-AIBatchAnalysis {
    <#
    .SYNOPSIS
    批量用 AI 分析文件
    #>
    param(
        [string]$Path = "C:\Logs",
        [string]$Filter = "*.log",
        [int]$TopN = 5,
        [int]$TailLines = 30
    )

    $files = Get-ChildItem $Path -Filter $Filter -Recurse |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $TopN

    foreach ($file in $files) {
        Write-Host "`n分析文件：$($file.Name)" -ForegroundColor Cyan
        $content = Get-Content $file.FullName -Tail $TailLines -ErrorAction SilentlyContinue

        if (-not $content) { continue }

        $summary = Invoke-OllamaChat -Model "llama3.2" -Prompt @"
分析以下日志摘要，用一句话总结关键发现：
$($content -join "`n")
"@

        Write-Host "  摘要：$summary" -ForegroundColor Green
    }
}

Invoke-AIBatchAnalysis -Path "C:\Logs" -TopN 3
```

执行结果示例：

```
分析文件：app-20250626.log
  摘要：数据库连接超时错误在 14:00-15:00 期间集中出现，建议检查连接池配置。

分析文件：app-20250625.log
  摘要：正常日志，无异常。

分析文件：security-20250626.log
  摘要：检测到 3 次来自 192.168.1.100 的登录失败尝试。
```

## 注意事项

1. **API 密钥安全**：不要将 API 密钥硬编码在脚本中，使用环境变量或 Azure Key Vault 存储
2. **速率限制**：OpenAI 等 API 有调用频率限制，批量处理时添加 `Start-Sleep` 控制速率
3. **成本控制**：AI API 按 Token 计费，生产环境中控制 `max_tokens` 参数，避免发送过多上下文
4. **本地模型**：Ollama 本地模型适合数据敏感场景，但需要足够的 GPU/CPU 资源
5. **响应验证**：AI 生成的脚本和建议需要人工审查，不要盲目执行 AI 生成的命令
6. **超时处理**：AI API 调用可能较慢，设置合理的 `Invoke-RestMethod` 超时时间
