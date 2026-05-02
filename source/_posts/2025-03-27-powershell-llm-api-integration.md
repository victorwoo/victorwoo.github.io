---
layout: post
date: 2025-03-27 08:00:00
updated: 2025-03-27 08:00:00
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
- network
---
_适用于 PowerShell 7.0 及以上版本_

大语言模型（LLM）已经渗透到开发工作的方方面面。当我们需要在自动化脚本中集成 AI 能力时，直接调用 OpenAI 兼容的 REST API 是最灵活的方式。PowerShell 内置的 `Invoke-RestMethod` cmdlet 天然适合完成这项工作——无需安装额外 SDK，几行代码即可实现与 LLM 的交互。

本文将从零开始，逐步带你完成 API Key 配置、单次问答封装、多轮对话、代码审查场景以及 Token 用量估算。

## 准备工作：配置 API Key

调用任何 OpenAI 兼容接口都需要一个 API Key。出于安全考虑，我们通过环境变量来管理它，避免在代码中硬编码。

```powershell
# 在 PowerShell 配置文件中添加（只需执行一次）
Add-Content -Path $PROFILE -Value '`$env:OPENAI_API_KEY = "sk-your-key-here"'
```

如果你使用的是国内中转代理或其他 OpenAI 兼容服务（如 Azure OpenAI、DeepSeek），还需要额外设置基础 URL：

```powershell
# 设置自定义 API 端点（可选）
$env:OPENAI_API_BASE = "https://your-proxy.example.com/v1"
```

配置完成后，重新打开 PowerShell 会话即可生效。你可以通过以下方式验证：

```
PS> $env:OPENAI_API_KEY
sk-proj-xxxxxxxxxxxxxx
```

## 单次问答：封装通用函数

下面我们封装一个 `Invoke-LLMChat` 函数，它接受用户提问，返回模型的回复。这个函数是后续所有场景的基础。

函数内部会自动读取环境变量中的 API Key，将用户消息和系统提示组装成 OpenAI Chat Completion 格式的 JSON，然后通过 `Invoke-RestMethod` 发送 POST 请求。

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

    # 检查 API Key 是否已配置
    $apiKey = $env:OPENAI_API_KEY
    if (-not $apiKey) {
        throw "请先设置环境变量 OPENAI_API_KEY"
    }

    # 确定请求地址：优先使用自定义端点
    $baseUrl = if ($env:OPENAI_API_BASE) { $env:OPENAI_API_BASE } else { "https://api.openai.com/v1" }
    $uri = "$baseUrl/chat/completions"

    # 构造请求体
    $body = @{
        model       = $Model
        messages    = @(
            @{ role = "system"; content = $SystemMessage }
            @{ role = "user";   content = $Prompt }
        )
        temperature = $Temperature
        max_tokens  = $MaxTokens
    } | ConvertTo-Json -Depth 5 -Compress

    # 发送请求（使用 UTF8 编码避免中文乱码）
    $response = Invoke-RestMethod `
        -Uri $uri `
        -Method Post `
        -Headers @{ Authorization = "Bearer $apiKey" } `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

    return $response.choices[0].message.content
}
```

这里有两个值得注意的细节：一是用 `-Compress` 参数减少 JSON 体积（去掉多余空白），二是用 `UTF8.GetBytes` 确保中文字符不会在传输中变成乱码。如果你不需要自定义端点，也可以省略 `$env:OPENAI_API_BASE` 相关逻辑。

调用示例：

```
PS> Invoke-LLMChat -Prompt "用一行 PowerShell 代码获取本机所有 IP 地址"

你可以使用以下命令获取本机所有 IP 地址：
(Get-NetIPAddress -AddressFamily IPv4).IPAddress
```

## 多轮对话：维护上下文历史

单次问答没有"记忆"。要让模型理解上下文，我们需要把完整的对话历史（包括之前的用户消息和助手回复）都发给 API。下面这个函数实现了一个交互式的多轮对话循环。

关键点在于 `$messages` 数组——每次用户发言后追加一条 user 消息，收到模型回复后追加一条 assistant 消息，这样上下文就在数组中不断累积。

```powershell
function Start-LLMConversation {
    param(
        [string]$Model = "gpt-4o-mini"
    )

    $apiKey = $env:OPENAI_API_KEY
    $baseUrl = if ($env:OPENAI_API_BASE) { $env:OPENAI_API_BASE } else { "https://api.openai.com/v1" }
    $uri = "$baseUrl/chat/completions"

    # 初始化对话历史，包含系统提示
    $messages = @(
        @{ role = "system"; content = "你是一个有帮助的助手，请用中文回答。" }
    )

    Write-Host "多轮对话已启动，输入 'exit' 退出" -ForegroundColor Cyan

    while ($true) {
        $userInput = Read-Host "你"
        if ($userInput -eq "exit") { break }
        if ([string]::IsNullOrWhiteSpace($userInput)) { continue }

        # 追加用户消息到历史
        $messages += @{ role = "user"; content = $userInput }

        $body = @{
            model    = $Model
            messages = $messages
        } | ConvertTo-Json -Depth 10 -Compress

        $response = Invoke-RestMethod `
            -Uri $uri `
            -Method Post `
            -Headers @{ Authorization = "Bearer $apiKey" } `
            -ContentType "application/json; charset=utf-8" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        $assistantMessage = $response.choices[0].message.content

        # 追加助手回复到历史，保持上下文连续
        $messages += @{ role = "assistant"; content = $assistantMessage }

        Write-Host "`n助手: $assistantMessage`n" -ForegroundColor Green

        # 显示 Token 消耗，帮助控制成本
        $usage = $response.usage
        Write-Host "[Token] 输入: $($usage.prompt_tokens) | 输出: $($usage.completion_tokens)" -ForegroundColor DarkGray
    }
}
```

运行效果：

```
PS> Start-LLMConversation
多轮对话已启动，输入 'exit' 退出
你: 写一个函数检查磁盘空间

助手: 这是一个检查磁盘空间的函数：

function Get-DiskSpace {
    param([string]$ComputerName = $env:COMPUTERNAME)
    Get-CimInstance -ClassName Win32_LogicalDisk ...
}

[Token] 输入: 28 | 输出: 156
你: 再加上邮件告警功能

助手: 好的，在原有函数基础上增加邮件告警：

function Get-DiskSpace {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [double]$ThresholdGB = 10,
        ...

[Token] 输入: 210 | 输出: 203
你: exit
```

可以看到第二轮对话中，输入 Token 从 28 涨到 210，因为整个对话历史都被带上了。这也提醒我们：多轮对话的 Token 消耗是递增的，长对话时需要考虑截断历史。

## 实战场景：代码审查助手

将 LLM 集成到日常工作流中，最实用的场景之一就是代码审查。我们读取一个脚本文件的内容，让模型从安全性、性能、可维护性等维度进行分析。

注意这里用数组拼接代替了 here-string，避免在内容中嵌入三反引号导致语法冲突。

```powershell
function Request-CodeReview {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # 读取脚本内容
    $code = Get-Content $ScriptPath -Raw

    # 用数组拼接构造提示词，避免 here-string 中出现三反引号
    $promptParts = @(
        "请审查以下 PowerShell 脚本，指出潜在问题并提供改进建议："
        ""
        "--- 脚本内容开始 ---"
        $code
        "--- 脚本内容结束 ---"
        ""
        "请从以下角度分析："
        "1. 安全性（注入风险、凭据处理）"
        "2. 性能（循环优化、管道使用）"
        "3. 可维护性（命名规范、错误处理）"
        "4. 兼容性（PowerShell 版本差异）"
    )
    $prompt = $promptParts -join "`n"

    $review = Invoke-LLMChat -Prompt $prompt -Model "gpt-4o" -MaxTokens 4096

    Write-Host "`n========== 代码审查报告 ==========`n" -ForegroundColor Yellow
    Write-Host $review
    Write-Host "`n==================================`n" -ForegroundColor Yellow
}
```

假设我们有一个脚本 `cleanup.ps1`，内容是简单的临时文件清理，执行审查后输出如下：

```
PS> Request-CodeReview -ScriptPath .\cleanup.ps1

========== 代码审查报告 ==========

## 代码审查结果

### 1. 安全性
- 第 3 行使用了硬编码路径 `C:\Temp`，建议改为参数化配置
- 缺少 `-WhatIf` 支持，建议添加 `[SupportsShouldProcess()]`

### 2. 性能
- `Get-ChildItem` 未使用 `-File` 参数，可能误删目录
- 建议添加 `-ErrorAction SilentlyContinue` 避免权限异常中断

### 3. 可维护性
- 缺少注释和帮助文档（Comment-Based Help）
- 变量 `$d` 命名不清晰，建议改为 `$daysOld`

### 4. 兼容性
- 使用了 PowerShell 7 的 `Ternernary` 运算符，Windows PowerShell 5.1 不兼容

==================================
```

## Token 用量估算

在频繁调用 API 的场景下，了解 Token 消耗非常重要。下面这个函数基于响应中的 `usage` 字段进行累计统计，帮你掌握每次调用的开销。

不同模型的单价不同，函数中提供了常见模型的参考价格（美元/千 Token），你可以根据实际情况调整。

```powershell
function Get-LLMTokenCost {
    param(
        [int]$PromptTokens,
        [int]$CompletionTokens,
        [string]$Model = "gpt-4o-mini"
    )

    # 常见模型价格表（美元/千 Token，仅供参考）
    $pricing = @{
        "gpt-4o"       = @{ Input = 0.005;  Output = 0.015 }
        "gpt-4o-mini"  = @{ Input = 0.00015; Output = 0.0006 }
        "gpt-3.5-turbo" = @{ Input = 0.0005; Output = 0.0015 }
    }

    $rate = $pricing[$Model]
    if (-not $rate) {
        Write-Warning "未找到模型 $Model 的定价信息"
        return
    }

    $inputCost = [math]::Round($PromptTokens * $rate.Input / 1000, 6)
    $outputCost = [math]::Round($CompletionTokens * $rate.Output / 1000, 6)
    $totalCost = [math]::Round($inputCost + $outputCost, 6)

    [PSCustomObject]@{
        模型     = $Model
        输入Token = $PromptTokens
        输出Token = $CompletionTokens
        总Token   = $PromptTokens + $CompletionTokens
        输入费用  = "`$$inputCost"
        输出费用  = "`$$outputCost"
        总费用    = "`$$totalCost"
    }
}
```

使用示例：

```
PS> Get-LLMTokenCost -PromptTokens 210 -CompletionTokens 203 -Model gpt-4o-mini

模型      输入Token 输出Token 总Token 输入费用   输出费用   总费用
----      -------- -------- ------- --------   --------  ------
gpt-4o-mini      210      203     413 $0.000032 $0.000122 $0.000154
```

可以看到，一次典型的多轮对话调用成本极低。但如果每天执行数百次自动化任务，费用仍然会累积，因此建议在脚本中加入 Token 上限控制。

## 注意事项

- **API Key 安全**：切勿将 Key 硬编码在脚本中或提交到代码仓库。使用环境变量或 Azure Key Vault 等密钥管理服务。可以在 `.gitignore` 中排除包含敏感信息的配置文件。
- **Token 限制**：每个模型有最大上下文窗口（如 `gpt-4o-mini` 为 128K）。多轮对话时注意累积的消息长度，必要时截断早期历史。建议在发送前估算 Token 数量（粗略规则：1 个汉字约 1-2 个 Token）。
- **国内代理**：如果无法直接访问 OpenAI API，可以设置 `$env:OPENAI_API_BASE` 指向国内代理。选择代理服务时注意数据隐私条款，避免敏感代码经第三方中转。
- **错误处理**：生产环境中建议在 `Invoke-RestMethod` 外包裹 `try/catch`，处理网络超时、API 限流（429 状态码）等异常情况。
- **流式响应**：本文示例使用非流式调用（等待完整响应后再返回）。如需实现打字机效果，可以使用 SSE（Server-Sent Events）模式，但实现复杂度较高，适合单独封装。
