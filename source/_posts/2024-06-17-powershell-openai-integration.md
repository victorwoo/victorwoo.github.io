---
layout: post
title: "使用 PowerShell 和 OpenAI 实现智能脚本生成"
date: 2024-06-17 00:00:00
description: 通过 OpenAI API 自动生成 PowerShell 脚本的技术实践
categories:
- powershell
tags:
- powershell
- ai
- automation
---

```powershell
# 配置 OpenAI API 密钥
$openAIKey = 'your-api-key'

function Get-AIScript {
    param(
        [string]$Prompt
    )

    $headers = @{
        'Authorization' = "Bearer $openAIKey"
        'Content-Type' = 'application/json'
    }

    $body = @{
        model = 'gpt-4'
        messages = @(
            @{
                role = 'system'
                content = '你是一个 PowerShell 专家，请生成符合最佳实践的脚本。要求：1. 包含错误处理 2. 支持verbose输出 3. 包含帮助文档'
            },
            @{
                role = 'user'
                content = $Prompt
            }
        )
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' -Method Post -Headers $headers -Body $body

    $response.choices[0].message.content
}

# 示例：生成 AD 用户创建脚本
$prompt = @"
创建 PowerShell 函数 New-ADUserWithValidation，要求：
1. 验证输入的邮箱格式
2. 检查用户名唯一性
3. 自动生成随机初始密码
4. 支持WhatIf参数
"@

Get-AIScript -Prompt $prompt
```

此脚本演示如何通过 OpenAI API 自动生成符合企业规范的 PowerShell 脚本。通过系统提示词确保生成的脚本包含错误处理、verbose 输出等必要元素。实际使用时可扩展以下功能：

1. 添加 Azure Key Vault 集成管理 API 密钥
2. 实现脚本静态分析
3. 与 CI/CD 流水线集成进行自动测试