---
layout: post
date: 2024-07-16 08:00:00
title: "PowerShell 技能连载 - 基于OpenAI的智能脚本生成"
description: "使用PowerShell集成GPT-4实现自然语言转运维脚本"
categories:
- powershell
- ai
- automation
tags:
- openai
- natural-language-processing
- devops
---

```powershell
function Invoke-AIScriptGeneration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$NaturalLanguageQuery,
        
        [ValidateRange(1,4096)]
        [int]$MaxTokens = 1024
    )

    $apiKey = Read-Host -Prompt '输入OpenAI API密钥' -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential ('api', $apiKey)

    $body = @{
        model = 'gpt-4-turbo-preview'
        messages = @(
            @{
                role = 'system'
                content = '你是一个PowerShell专家，将自然语言查询转换为可执行的PowerShell脚本。确保代码符合最佳安全实践，包含错误处理，并添加中文注释。'
            },
            @{
                role = 'user'
                content = $NaturalLanguageQuery
            }
        )
        temperature = 0.2
        max_tokens = $MaxTokens
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' \
            -Method POST \
            -Headers @{ Authorization = 'Bearer ' + $cred.GetNetworkCredential().Password } \
            -ContentType 'application/json' \
            -Body $body

        $scriptBlock = [scriptblock]::Create($response.choices[0].message.content)
        $transcript = [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            OriginalQuery = $NaturalLanguageQuery
            GeneratedScript = $response.choices[0].message.content
            TokenUsage = $response.usage
        }

        $transcript | Export-Clixml -Path "$env:TEMP/AIScriptTranscript_$(Get-Date -Format yyyyMMdd).xml"
        return $scriptBlock
    }
    catch {
        Write-Error "AI脚本生成失败: $_"
    }
}
```

**核心功能**：
1. 自然语言转PowerShell脚本
2. 自动生成安全凭据处理
3. 脚本转录与审计跟踪
4. 智能温度控制与令牌限制

**应用场景**：
- 快速原型开发
- 运维知识库建设
- 跨团队协作标准化
- 新人上岗培训