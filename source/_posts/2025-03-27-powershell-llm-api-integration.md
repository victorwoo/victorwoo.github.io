---
layout: post
date: 2025-03-27 08:00:00
title: "PowerShell 技能连载 - 调用大语言模型 API"
description: PowerTip of the Day - Calling LLM APIs from PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
---
随着 ChatGPT、Claude 等大语言模型的普及，越来越多的自动化场景需要从脚本中直接调用 LLM API。PowerShell 作为 Windows 平台的首选脚本语言，调用 REST API 非常方便。

## 基础调用

```powershell
function Invoke-LLMChat {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Model = "gpt-4o-mini",

        [string]$SystemMessage = "你是一个有帮助的 PowerShell 助手。",

        [double]$Temperature = 0.7,

        [int]$MaxTokens = 2048
    )

    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        throw "请设置环境变量 OPENAI_API_KEY"
    }

    $body = @{
        model       = $Model
        messages    = @(
            @{ role = "system"; content = $SystemMessage }
            @{ role = "user";   content = $Prompt }
        )
        temperature = $Temperature
        max_tokens  = $MaxTokens
    } | ConvertTo-Json -Depth 5

    $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/chat/completions" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $apiKey" } `
        -ContentType "application/json" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    return $response.choices[0].message.content
}
```

## 多轮对话

```powershell
function Start-LLMConversation {
    param(
        [string]$Model = "gpt-4o-mini"
    )

    $apiKey = $env:OPENAI_API_KEY
    $messages = @(
        @{ role = "system"; content = "你是一个有帮助的助手，请用中文回答。" }
    )

    Write-Host "输入 'exit' 退出对话" -ForegroundColor Cyan

    while ($true) {
        $userInput = Read-Host "你"
        if ($userInput -eq "exit") { break }

        $messages += @{ role = "user"; content = $userInput }

        $body = @{
            model    = $Model
            messages = $messages
        } | ConvertTo-Json -Depth 10

        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/chat/completions" `
            -Method Post `
            -Headers @{ Authorization = "Bearer $apiKey" } `
            -ContentType "application/json" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        $assistantMessage = $response.choices[0].message.content
        $messages += @{ role = "assistant"; content = $assistantMessage }

        Write-Host "`n助手: $assistantMessage`n" -ForegroundColor Green

        $usage = $response.usage
        Write-Host "Token 用量 - 输入: $($usage.prompt_tokens), 输出: $($usage.completion_tokens)" -ForegroundColor DarkGray
    }
}
```

## 实用场景：代码审查助手

```powershell
function Request-CodeReview {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    $code = Get-Content $ScriptPath -Raw
    $prompt = @(
        "请审查以下 PowerShell 脚本，指出潜在问题并提供改进建议："
        ""
        "```powershell"
        $code
        "```"
        ""
        "请从以下角度分析："
        "1. 安全性（注入风险、凭据处理）"
        "2. 性能（循环优化、管道使用）"
        "3. 可维护性（命名规范、错误处理）"
        "4. 兼容性（PowerShell 版本差异）"
    ) -join "`n"

    $review = Invoke-LLMChat -Prompt $prompt -Model "gpt-4o"
    Write-Host $review
}
```

## Token 用量统计

```powershell
function Get-LLMUsage {
    param(
        [datetime]$StartDate = (Get-Date).AddDays(-30),
        [datetime]$EndDate = (Get-Date)
    )

    $apiKey = $env:OPENAI_API_KEY

    $response = Invoke-RestMethod `
        -Uri "https://api.openai.com/v1/usage?start_date=$($StartDate.ToString('yyyy-MM-dd'))&end_date=$($EndDate.ToString('yyyy-MM-dd'))" `
        -Headers @{ Authorization = "Bearer $apiKey" }

    $response.data | ForEach-Object {
        [PSCustomObject]@{
            Date         = $_.aggregation_timestamp
            Model        = $_.model
            PromptTokens = $_.n_prompt_tokens
            CompletionTokens = $_.n_completion_tokens
            CostUSD      = [math]::Round($_.n_generated_tokens_total * 0.00003, 4)
        }
    } | Format-Table -AutoSize
}
```

调用 LLM API 时注意控制 Token 消耗，System Message 尽量精简，生产环境建议设置 MaxTokens 上限。
