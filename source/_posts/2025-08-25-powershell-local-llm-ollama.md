---
layout: post
date: 2025-08-25 08:00:00
title: "PowerShell 技能连载 - 本地大模型运维助手"
description: PowerTip of the Day - Local LLM Operations Assistant in PowerShell
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
- ollama
- local-llm
---

_适用于 PowerShell 7.0 及以上版本，需要安装 Ollama_

数据安全和隐私合规要求使得很多企业无法使用云端 AI 服务。本地部署的大语言模型（如通过 Ollama 运行的 Llama、Qwen、DeepSeek 等）提供了完全内网的 AI 能力——日志智能分析、故障根因推理、脚本自动生成、配置合规审查，所有数据不出内网。结合 PowerShell 的系统管理能力和本地 AI 的推理能力，可以构建强大的智能运维助手。

本文将讲解如何使用 PowerShell 构建基于本地大模型的运维自动化工具。

## Ollama 环境准备

```powershell
# 检查 Ollama 状态
function Test-OllamaStatus {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
        Write-Host "Ollama 运行中" -ForegroundColor Green
        Write-Host "可用模型：" -ForegroundColor Cyan
        foreach ($model in $response.models) {
            $sizeGB = [math]::Round($model.size / 1GB, 2)
            Write-Host "  $($model.name) ($sizeGB GB) - 修改于 $($model.modified_at.Substring(0, 10))"
        }
        return $true
    } catch {
        Write-Host "Ollama 未运行" -ForegroundColor Red
        Write-Host "启动方式：ollama serve" -ForegroundColor Yellow
        return $false
    }
}

Test-OllamaStatus

# 拉取模型
function Install-OllamaModel {
    param([Parameter(Mandatory)][string]$ModelName)

    Write-Host "拉取模型：$ModelName（可能需要较长时间）..." -ForegroundColor Cyan
    $body = @{ name = $ModelName } | ConvertTo-Json

    Invoke-RestMethod -Uri "http://localhost:11434/api/pull" `
        -Method Post -Body $body -ContentType "application/json"
    Write-Host "模型已下载：$ModelName" -ForegroundColor Green
}

# Install-OllamaModel -ModelName "qwen2.5-coder:7b"
```

执行结果示例：

```
Ollama 运行中
可用模型：
  llama3.2:latest (2.02 GB) - 修改于 2025-07-15
  qwen2.5-coder:7b (4.67 GB) - 修改于 2025-07-20
```

## 本地 AI 调用封装

```powershell
function Invoke-LocalAI {
    <#
    .SYNOPSIS
    调用本地 Ollama 模型
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$SystemPrompt = "你是一个 PowerShell 运维专家。回答简洁，用中文。",

        [string]$Model = "qwen2.5-coder:7b",

        [double]$Temperature = 0.3,

        [switch]$ShowProgress
    )

    $body = @{
        model       = $Model
        system      = $SystemPrompt
        prompt      = $Prompt
        stream      = $false
        options     = @{
            temperature = $Temperature
            num_predict = 2048
        }
    } | ConvertTo-Json -Depth 5

    if ($ShowProgress) {
        Write-Host "思考中..." -ForegroundColor DarkGray -NoNewline
    }

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" `
            -Method Post `
            -Body $body `
            -ContentType "application/json; charset=utf-8" `
            -TimeoutSec 120

        if ($ShowProgress) { Write-Host "`r完成！   " -ForegroundColor Green }

        return $response.response
    } catch {
        if ($ShowProgress) { Write-Host "`r失败！   " -ForegroundColor Red }
        throw "AI 调用失败：$($_.Exception.Message)"
    }
}

# 基础使用
$answer = Invoke-LocalAI -Prompt "如何在 PowerShell 中获取所有已停止的自动启动服务？" -ShowProgress
Write-Host $answer
```

执行结果示例：

```
完成！
可以使用以下命令获取所有已停止的自动启动服务：

Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
```

## 智能日志分析

```powershell
function Invoke-AILogAnalysis {
    <#
    .SYNOPSIS
    使用本地 AI 分析日志文件
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$TailLines = 50,

        [string]$Model = "qwen2.5-coder:7b"
    )

    Write-Host "分析日志：$LogPath" -ForegroundColor Cyan

    $content = Get-Content $LogPath -Tail $TailLines -ErrorAction Stop
    $logText = $content -join "`n"

    $prompt = @"
请分析以下服务器日志，找出：
1. 关键错误和异常
2. 可能的根因
3. 建议的修复步骤

日志内容（最近 $TailLines 行）：
$logText
"@

    $analysis = Invoke-LocalAI -Prompt $prompt -Model $Model `
        -SystemPrompt "你是一个资深运维工程师，擅长日志分析和故障排查。用中文回答，结构清晰。" `
        -Temperature 0.2

    Write-Host "`n=== AI 日志分析报告 ===" -ForegroundColor Cyan
    Write-Host $analysis
    return $analysis
}

# 分析应用日志
Invoke-AILogAnalysis -LogPath "C:\Logs\MyApp\app.log" -TailLines 30
```

执行结果示例：

```
分析日志：C:\Logs\MyApp\app.log

=== AI 日志分析报告 ===
1. 关键错误：
   - 14:30:15 数据库连接超时（Timeout expired）
   - 14:35:20 消息队列写入失败
   - 14:40:30 服务健康检查失败

2. 可能根因：
   - 数据库连接池耗尽，导致后续操作级联失败
   - 连接池 Max Pool Size=100，但并发请求峰值达到 200+

3. 修复建议：
   - 增大连接池：Max Pool Size=200
   - 添加连接超时重试逻辑
   - 检查是否有未正确关闭的数据库连接
```

## 配置合规审查

```powershell
function Invoke-AIConfigReview {
    <#
    .SYNOPSIS
    使用 AI 审查配置文件的安全性
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    $content = Get-Content $ConfigPath -Raw -ErrorAction Stop
    $fileName = Split-Path $ConfigPath -Leaf

    $prompt = @"
请审查以下配置文件（$fileName），检查：
1. 安全风险（硬编码密码、不安全的协议、过弱的加密）
2. 性能问题（不合理的超时、缓存配置）
3. 最佳实践建议

配置文件内容：
$content
"@

    $review = Invoke-LocalAI -Prompt $prompt `
        -SystemPrompt "你是安全审计专家，专注于配置文件安全审查。用中文回答，按风险等级排序。" `
        -Temperature 0.1

    Write-Host "`n=== 配置审查报告：$fileName ===" -ForegroundColor Cyan
    Write-Host $review
}

# 审查配置文件
Invoke-AIConfigReview -ConfigPath "C:\MyApp\appsettings.json"
```

执行结果示例：

```
=== 配置审查报告：appsettings.json ===
安全风险（高）：
- 发现硬编码的数据库密码：ConnectionString 中包含 P@ssw0rd
  建议：使用环境变量或 Azure Key Vault

安全风险（中）：
- CORS 配置允许所有来源：AllowAnyOrigin = true
  建议：限制为具体域名

最佳实践建议：
- 建议启用 HTTPS 严格传输安全（HSTS）
- 日志级别在生产环境应为 Warning，当前为 Debug
```

## 批量运维辅助

```powershell
# AI 辅助生成运维脚本
function Get-AIScript {
    param(
        [Parameter(Mandatory)]
        [string]$Description
    )

    $prompt = @"
请根据以下描述生成一个 PowerShell 脚本。要求：
1. 包含参数验证
2. 包含错误处理（try/catch）
3. 使用 Write-Host 输出带颜色的状态信息
4. 代码简洁实用，不要过度设计

需求描述：$Description
"@

    $script = Invoke-LocalAI -Prompt $prompt `
        -SystemPrompt "你是 PowerShell 脚本专家。只输出代码，不要解释。" `
        -Temperature 0.2

    return $script
}

# 生成脚本
$generated = Get-AIScript -Description "监控多个远程服务器的 CPU 和内存使用率，超过阈值时输出告警"
Write-Host $generated

# AI 辅助解释命令
function Get-AIExplanation {
    param([Parameter(Mandatory)][string]$Command)

    $explanation = Invoke-LocalAI -Prompt "简要解释以下 PowerShell 命令的作用：$Command" `
        -Temperature 0.1

    Write-Host $explanation
}

Get-AIExplanation -Command "Get-ChildItem | Where-Object { $_.Length -gt 1MB } | Sort-Object Length -Descending | Select-Object -First 10 Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,1)}}"
```

执行结果示例：

```
这个命令在当前目录中查找大于 1MB 的文件，按大小降序排列，显示最大的 10 个文件的名称和大小（MB）。
```

## 注意事项

1. **资源需求**：本地 LLM 需要大量内存/显存，7B 模型至少需要 8GB 内存，13B 需要 16GB+
2. **推理速度**：没有 GPU 时推理较慢（CPU 模式每秒几 token），生产环境建议使用 GPU
3. **模型选择**：运维场景推荐代码类模型（Qwen-Coder、DeepSeek-Coder），通用能力更强
4. **提示词工程**：AI 输出质量取决于提示词质量，提供明确的上下文和格式要求
5. **输出验证**：AI 生成的脚本必须经过人工审查和测试，不能盲目执行
6. **数据隐私**：虽然数据不出内网，但仍需注意不要将敏感信息（密码、密钥）传入 AI
