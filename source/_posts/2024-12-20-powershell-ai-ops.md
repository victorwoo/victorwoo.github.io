---
layout: post
date: 2024-12-20 08:00:00
title: "PowerShell 技能连载 - 智能运维中的自然语言脚本生成"
description: PowerTip of the Day - Natural Language Script Generation with OpenAI
categories:
- powershell
- ai
tags:
- powershell
- ai
- automation
---

```powershell
function Invoke-AIOpsAssistant {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [int]$MaxTokens = 200
    )

    $apiKey = 'sk-xxxxxxxxxxxx'
    $headers = @{
        'Authorization' = "Bearer $apiKey"
        'Content-Type' = 'application/json'
    }

    $body = @{
        model = 'gpt-3.5-turbo'
        messages = @(
            @{
                role = 'system'
                content = '你是一个PowerShell专家，根据用户需求生成可直接运行的脚本。要求：1) 使用原生命令 2) 添加详细注释 3) 包含错误处理'
            },
            @{
                role = 'user'
                content = $Prompt
            }
        )
        max_tokens = $MaxTokens
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' \
            -Method Post \
            -Headers $headers \
            -Body $body

        $generatedCode = $response.choices[0].message.content
        $tempScript = [System.IO.Path]::GetTempFileName() + '.ps1'
        $generatedCode | Out-File -FilePath $tempScript
        & $tempScript
    }
    catch {
        Write-Error "AI脚本生成失败：$_"
    }
}
```

核心功能：
1. 集成OpenAI ChatGPT API实现自然语言转PowerShell脚本
2. 自动生成带错误处理和注释的生产级代码
3. 安全执行临时脚本文件
4. 支持自定义提示工程参数

应用场景：
- 快速生成AD用户批量管理脚本
- 自动创建资源监控报表
- 生成复杂日志分析管道命令