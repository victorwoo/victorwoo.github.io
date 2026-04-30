---
layout: post
date: 2025-04-03 08:00:00
title: "PowerShell 技能连载 - 本地大模型 Ollama 集成"
description: PowerTip of the Day - Integrating Ollama Local LLM with PowerShell
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
在数据隐私敏感或网络受限的场景下，本地运行大语言模型是更好的选择。Ollama 提供了简洁的本地 API，PowerShell 可以直接调用，无需额外 SDK。

## 环境准备

```powershell
function Test-OllamaAvailable {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method Get -TimeoutSec 5
        $models = $response.models | Select-Object name, size, modified_at

        if ($models) {
            Write-Host "Ollama 已运行，可用模型:" -ForegroundColor Green
            $models | ForEach-Object {
                $sizeGB = [math]::Round($_.size / 1GB, 2)
                [PSCustomObject]@{
                    Model    = $_.name
                    SizeGB   = $sizeGB
                    Modified = $_.modified_at
                }
            } | Format-Table -AutoSize
        }
        else {
            Write-Host "Ollama 已运行，但尚未下载模型" -ForegroundColor Yellow
        }
        return $true
    }
    catch {
        Write-Host "Ollama 未运行，请先执行: ollama serve" -ForegroundColor Red
        return $false
    }
}

function Install-OllamaModel {
    param(
        [Parameter(Mandatory)]
        [string]$Model = "qwen2.5:7b"
    )

    Write-Host "正在下载模型: $Model ..."
    $process = Start-Process -FilePath "ollama" -ArgumentList "pull", $Model -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "模型下载完成" -ForegroundColor Green
    }
    else {
        Write-Host "下载失败，退出码: $($process.ExitCode)" -ForegroundColor Red
    }
}
```

## 基础对话

```powershell
function Invoke-OllamaChat {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string]$Model = "qwen2.5:7b",

        [string]$System = "你是一个有帮助的助手。",

        [double]$Temperature = 0.7,

        [switch]$Stream
    )

    $body = @{
        model    = $Model
        messages = @(
            @{ role = "system"; content = $System }
            @{ role = "user";   content = $Prompt }
        )
        options  = @{
            temperature = $Temperature
        }
        stream   = $Stream.IsPresent
    } | ConvertTo-Json -Depth 5

    if ($Stream) {
        # 流式输出
        $response = Invoke-WebRequest `
            -Uri "http://localhost:11434/api/chat" `
            -Method Post `
            -ContentType "application/json" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        $lines = $response.Content -split "`n" | Where-Object { $_.Trim() }
        $fullText = ""

        foreach ($line in $lines) {
            $json = $line | ConvertFrom-Json
            $fullText += $json.message.content
        }

        return $fullText
    }
    else {
        $response = Invoke-RestMethod `
            -Uri "http://localhost:11434/api/chat" `
            -Method Post `
            -ContentType "application/json" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        return $response.message.content
    }
}
```

## PowerShell 代码生成

```powershell
function Get-LLMPowerShellHelp {
    param(
        [Parameter(Mandatory)]
        [string]$Question,

        [string]$Model = "qwen2.5-coder:7b"
    )

    $systemPrompt = @"
你是 PowerShell 专家。回答要求：
1. 提供可直接运行的代码
2. 包含注释说明关键步骤
3. 包含错误处理
4. 优先使用 PowerShell 7 语法
"@

    $answer = Invoke-OllamaChat -Prompt $Question -Model $Model -System $systemPrompt

    Write-Host "`n$answer`n" -ForegroundColor Cyan

    # 保存到剪贴板
    Set-Clipboard -Value $answer
    Write-Host "已复制到剪贴板" -ForegroundColor DarkGray
}

# 示例
Get-LLMPowerShellHelp -Question "如何递归查找所有超过 100MB 的文件并导出 CSV？"
```

## 日志分析助手

```powershell
function Find-LogAnomaly {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$MaxLines = 200,

        [string]$Model = "qwen2.5:7b"
    )

    # 读取日志尾部
    $logs = Get-Content $LogPath -Tail $MaxLines -ErrorAction SilentlyContinue
    if (-not $logs) {
        throw "无法读取日志: $LogPath"
    }

    $logContent = $logs -join "`n"

    $prompt = @"
分析以下日志内容，找出异常和潜在问题：

$logContent

请列出：
1. 错误类型和出现次数
2. 异常时间模式
3. 可能的根本原因
4. 建议的处理措施
"@

    $analysis = Invoke-OllamaChat -Prompt $prompt -Model $Model -Temperature 0.3

    [PSCustomObject]@{
        LogFile  = $LogPath
        Lines    = $logs.Count
        Analysis = $analysis
        Timestamp = Get-Date
    }
}
```

## 批量文档摘要

```powershell
function Get-LLMDocumentSummary {
    param(
        [Parameter(Mandatory)]
        [string[]]$FilePaths,

        [string]$Model = "qwen2.5:7b",

        [int]$MaxContentLength = 8000
    )

    $summaries = foreach ($path in $FilePaths) {
        if (-not (Test-Path $path)) {
            Write-Warning "文件不存在: $path"
            continue
        }

        $content = Get-Content $path -Raw -ErrorAction SilentlyContinue
        if ($content.Length -gt $MaxContentLength) {
            $content = $content.Substring(0, $MaxContentLength) + "...(已截断)"
        }

        $prompt = "请用 3-5 句话总结以下文档的核心内容：`n`n$content"

        $summary = Invoke-OllamaChat -Prompt $prompt -Model $Model -Temperature 0.3

        [PSCustomObject]@{
            File    = Split-Path $path -Leaf
            Summary = $summary
        }

        Write-Host "." -NoNewline
    }

    Write-Host ""
    return $summaries
}

# 示例：总结当前目录下的 README 文件
$readmes = Get-ChildItem -Path . -Filter "README*" -Recurse | Select-Object -ExpandProperty FullName
Get-LLMDocumentSummary -FilePaths $readmes | Format-List
```

## 模型性能对比

```powershell
function Compare-OllamaModels {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [string[]]$Models = @("qwen2.5:7b", "llama3.2:3b", "gemma2:9b"),

        [int]$Iterations = 1
    )

    $results = @()

    foreach ($model in $Models) {
        for ($i = 0; $i -lt $Iterations; $i++) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            $response = Invoke-OllamaChat -Prompt $Prompt -Model $model -Temperature 0
            $sw.Stop()

            $results += [PSCustomObject]@{
                Model    = $model
                Run      = $i + 1
                TimeMs   = $sw.ElapsedMilliseconds
                Length   = $response.Length
                Response = $response.Substring(0, [Math]::Min(200, $response.Length)) + "..."
            }

            Write-Host "$model 第 $($i+1) 次: $($sw.ElapsedMilliseconds)ms" -ForegroundColor DarkGray
        }
    }

    $results | Select-Object Model, Run, TimeMs, Length |
        Sort-Object TimeMs |
        Format-Table -AutoSize
}
```

本地模型的推理速度取决于硬件配置。日常使用推荐 7B 参数量的模型（约 4GB 显存），代码任务优先选 coder 版本。如果有多张 GPU，设置 `OLLAMA_GPU_LAYERS` 环境变量可以优化推理性能。
