---
layout: post
date: 2024-08-14 08:00:00
title: "PowerShell 技能连载 - AI 辅助脚本生成"
description: PowerTip of the Day - AI Assisted Script Generation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
随着AI技术的进步，PowerShell现在可以通过集成AI模型实现智能代码建议功能。本方案通过封装OpenAI API实现脚本自动生成：

```powershell
function Get-AIScriptSuggestion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskDescription,
        
        [ValidateRange(0.1,1.0)]
        [double]$Creativity = 0.7
    )
    
    try {
        $apiKey = $env:OPENAI_KEY
        $headers = @{
            'Authorization' = "Bearer $apiKey"
            'Content-Type' = 'application/json'
        }

        $body = @{
            model = "gpt-4-turbo"
            messages = @(
                @{
                    role = "system"
                    content = "你是一个PowerShell专家，用简洁规范的代码解决问题。输出格式：\n```powershell\n<代码>\n```\n\n代码说明："
                },
                @{
                    role = "user"
                    content = $TaskDescription
                }
            )
            temperature = $Creativity
        } | ConvertTo-Json -Depth 5

        $response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' \
            -Method Post \
            -Headers $headers \
            -Body $body

        $response.choices[0].message.content
    }
    catch {
        Write-Error "AI请求失败: $_"
    }
}
```

工作原理：
1. 函数接收任务描述和创意系数参数，通过环境变量获取API密钥
2. 构建符合OpenAI要求的请求结构，包含系统角色提示词
3. 使用Invoke-RestMethod发起API调用
4. 返回格式化的PowerShell代码建议
5. 错误处理模块捕获网络异常和API限制错误

使用示例：
```powershell
$env:OPENAI_KEY = 'your-api-key'
Get-AIScriptSuggestion -TaskDescription "需要批量重命名目录中所有.jpg文件，添加日期前缀"
```

最佳实践：
1. 通过环境变量管理敏感信息
2. 限制temperature参数控制输出稳定性
3. 添加请求重试逻辑应对速率限制
4. 缓存常见查询结果减少API调用

注意事项：
• 需注册OpenAI账户获取API密钥
• 建议添加使用量监控
• 重要脚本需人工审核后执行