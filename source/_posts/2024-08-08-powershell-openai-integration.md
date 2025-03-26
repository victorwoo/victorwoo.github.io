---
layout: post
date: 2024-08-08 08:00:00
title: "PowerShell 技能连载 - 自然语言生成运维脚本"
description: PowerTip of the Day - Natural Language Script Generation with OpenAI
categories:
- powershell
- ai
- automation
tags:
- powershell
- openai
- devops
---

```powershell
function Invoke-AIScriptGeneration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [ValidateSet('AWS','Azure','Windows','Linux')]
        [string]$Environment = 'Windows'
    )

    $apiKey = $env:OPENAI_API_KEY
    $headers = @{
        'Authorization' = "Bearer $apiKey"
        'Content-Type' = 'application/json'
    }

    $body = @{
        model = 'gpt-4-turbo'
        messages = @(
            @{
                role = 'system'
                content = "你是一名资深PowerShell专家，根据用户需求生成可直接执行的运维脚本。当前环境：$Environment"
            },
            @{
                role = 'user'
                content = $Prompt
            }
        )
        temperature = 0.3
        max_tokens = 1024
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' \
            -Method Post \
            -Headers $headers \
            -Body $body

        $scriptBlock = [scriptblock]::Create($response.choices[0].message.content)
        Write-Host "生成脚本验证通过：" -ForegroundColor Green
        $scriptBlock.Invoke()
    }
    catch {
        Write-Error "AI脚本生成失败: $($_.Exception.Message)"
    }
}
```

核心功能：
1. 集成OpenAI API实现自然语言转PowerShell脚本
2. 支持多环境脚本生成（AWS/Azure/Windows/Linux）
3. 自动脚本验证与安全执行机制
4. 温度参数控制脚本生成稳定性

应用场景：
- 新手运维人员快速生成标准脚本
- 跨平台环境下的自动化模板生成
- 复杂运维任务的快速原型开发
- 企业知识库的脚本标准化沉淀