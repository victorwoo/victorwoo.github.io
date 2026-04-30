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
- llm
- ollama
- local-llm
---

_适用于 PowerShell 7.0 及以上版本，需要安装 Ollama_

前一篇我们探讨了 PowerShell 调用云端 AI API 的方式。然而在很多场景下——企业内网环境、数据合规要求、或者仅仅是不想为每一次调试付费——本地运行大语言模型是更务实的选择。Ollama 把模型下载、推理服务、REST API 打包成一条命令就能跑起来的体验，而 PowerShell 作为胶水语言，可以快速将这些能力集成到日常工作流中。

## 环境检查与模型下载

一切从确认 Ollama 是否可用开始。下面的函数会检测本地服务状态，并列出已下载的模型及其磁盘占用。

```powershell
function Test-OllamaAvailable {
    try {
        # 尝试访问 Ollama 本地 API，获取已安装模型列表
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

Test-OllamaAvailable
```

执行后如果 Ollama 已经在运行，你会看到类似输出：

```
Ollama 已运行，可用模型:

Model           SizeGB Modified
-----           ------ --------
qwen2.5:7b       4.36 2025-04-02T10:15:00Z
qwen2.5-coder:7b 4.42 2025-04-01T18:30:00Z
llama3.2:3b      1.89 2025-03-28T09:00:00Z
```

如果 Ollama 正在运行但还没有模型，可以用下面的函数拉取你需要的模型。

```powershell
function Install-OllamaModel {
    param(
        [Parameter(Mandatory)]
        [string]$Model = "qwen2.5:7b"
    )

    Write-Host "正在下载模型: $Model ..."
    $process = Start-Process -FilePath "ollama" -ArgumentList "pull", $Model -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "模型下载完成: $Model" -ForegroundColor Green
    }
    else {
        Write-Host "下载失败，退出码: $($process.ExitCode)" -ForegroundColor Red
    }
}

# 下载一个适合代码任务的模型
Install-OllamaModel -Model "qwen2.5-coder:7b"
```

首次下载根据网速需要几分钟到十几分钟不等：

```
正在下载模型: qwen2.5-coder:7b ...
pulling manifest...
downloading 8c47... 100%
verifying sha256...
writing layer...
模型下载完成: qwen2.5-coder:7b
```

## 基础对话

模型就绪后，我们先封装一个通用的对话函数。它封装了 Ollama 的 Chat API，支持系统提示词、温度控制和流式输出。

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

    # 构造请求体，包含系统提示和用户消息
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
        # 流式输出：逐块接收并拼接完整响应
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
        # 非流式：一次性返回完整内容
        $response = Invoke-RestMethod `
            -Uri "http://localhost:11434/api/chat" `
            -Method Post `
            -ContentType "application/json" `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        return $response.message.content
    }
}
```

用一句话试试看效果：

```powershell
Invoke-OllamaChat -Prompt "用一句话解释什么是 PowerShell 管道" -Model "qwen2.5:7b"
```

```
PowerShell 管道是一种将一个命令的输出对象直接作为下一个命令的输入的机制，使多个命令能够链式协作完成复杂任务。
```

## 代码生成助手

基础对话函数在手，我们可以针对特定场景定制系统提示词。下面这个函数专门用于生成 PowerShell 代码，回答风格被约束为"代码优先、注释清晰、包含错误处理"。

```powershell
function Get-LLMPowerShellHelp {
    param(
        [Parameter(Mandatory)]
        [string]$Question,

        [string]$Model = "qwen2.5-coder:7b"
    )

    # 精心设计的系统提示，约束输出格式和质量
    $systemPrompt = @"
你是 PowerShell 专家。回答要求：
1. 提供可直接运行的代码
2. 包含注释说明关键步骤
3. 包含错误处理
4. 优先使用 PowerShell 7 语法
"@

    $answer = Invoke-OllamaChat -Prompt $Question -Model $Model -System $systemPrompt

    Write-Host "`n$answer`n" -ForegroundColor Cyan

    # 方便直接粘贴使用
    Set-Clipboard -Value $answer
    Write-Host "已复制到剪贴板" -ForegroundColor DarkGray
}

Get-LLMPowerShellHelp -Question "如何递归查找所有超过 100MB 的文件并导出 CSV？"
```

```
以下脚本递归扫描指定路径，找出大于 100MB 的文件并导出到 CSV：

```powershell
# 设置搜索路径和输出文件
$SearchPath = "C:\Users"
$OutputCsv  = "$HOME\large-files.csv"

# 递归查找大文件，跳过无权限的目录
$largeFiles = Get-ChildItem -Path $SearchPath -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB } |
    Select-Object FullName,
        @{ N='SizeMB'; E={ [math]::Round($_.Length / 1MB, 2) } },
        LastWriteTime |
    Sort-Object SizeMB -Descending

# 导出到 CSV（UTF-8 编码，Excel 友好）
$largeFiles | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding utf8

Write-Host "找到 $($largeFiles.Count) 个文件，已保存到 $OutputCsv"
````
```

## 日志分析

本地模型的一个实际用途是分析服务器日志。将日志尾部发送给模型，让它帮你识别错误模式、异常时间分布和可能的根因。

```powershell
function Find-LogAnomaly {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$MaxLines = 200,

        [string]$Model = "qwen2.5:7b"
    )

    # 读取日志尾部，避免一次性加载过大文件
    $logs = Get-Content $LogPath -Tail $MaxLines -ErrorAction SilentlyContinue
    if (-not $logs) {
        throw "无法读取日志: $LogPath"
    }

    $logContent = $logs -join "`n"

    # 结构化的分析提示词，引导模型给出可操作的结论
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
        LogFile   = $LogPath
        Lines     = $logs.Count
        Analysis  = $analysis
        Timestamp = Get-Date
    }
}

Find-LogAnomaly -LogPath "/var/log/nginx/error.log" | Format-List
```

```
LogFile   : /var/log/nginx/error.log
Lines     : 200
Analysis  : 日志分析结果如下：
            1. 错误类型及次数：
               - 502 Bad Gateway：47 次（集中出现）
               - 504 Gateway Timeout：12 次
               - 连接被拒绝：8 次
            2. 异常时间模式：
               - 502 错误集中在 14:00-14:30，可能是后端服务重启
               - 504 超时在凌晨 03:00 左右出现，对应定时任务高峰
            3. 可能的根因：
               - 上游服务在 14:15 前后进行了部署，导致连接中断
               - 凌晨定时任务消耗大量资源，引发超时
            4. 建议：
               - 在部署期间配置健康检查和重试机制
               - 将资源密集型定时任务错峰执行
Timestamp : 2025/4/3 10:30:00
```

## 批量文档摘要

处理大量文档时，逐个阅读效率很低。下面的函数可以对一批文件自动生成摘要，适合快速了解项目文档、会议纪要或技术报告的核心内容。

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

        # 读取文件内容，超长时截断以适配模型上下文窗口
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

```
...
File    : README.md
Summary : 这是一个基于 Hexo 的技术博客项目，使用 NexT 主题。项目包含自动化部署脚本，
          支持通过 GitHub Actions 实现持续集成。主要文章涵盖 PowerShell 技巧、
          DevOps 实践和 AI 工具集成等内容。

File    : README.en.md
Summary : English version of the project README, describing the blog setup,
          theme configuration, and deployment workflow.
```

## 模型性能对比

不同模型在推理速度和回答质量上差异明显。下面的函数对同一问题在不同模型间做基准测试，帮助你选出最适合当前任务的模型。

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

            # 记录每次推理的耗时和输出长度
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

    # 按耗时排序输出对比表格
    $results | Select-Object Model, Run, TimeMs, Length |
        Sort-Object TimeMs |
        Format-Table -AutoSize
}

Compare-OllamaModels -Prompt "解释 RESTful API 的核心设计原则" -Iterations 2
```

```
llama3.2:3b  第 1 次: 6230ms
llama3.2:3b  第 2 次: 5980ms
qwen2.5:7b   第 1 次: 12840ms
qwen2.5:7b   第 2 次: 12510ms
gemma2:9b    第 1 次: 21350ms
gemma2:9b    第 2 次: 20890ms

Model          Run TimeMs Length
-----          --- ------ ------
llama3.2:3b      1   6230    386
llama3.2:3b      2   5980    402
qwen2.5:7b       1  12840    512
qwen2.5:7b       2  12510    498
gemma2:9b        1  21350    623
gemma2:9b        2  20890    610
```

本地模型的推理速度取决于硬件配置。日常使用推荐 7B 参数量的模型（约 4GB 显存），代码任务优先选 coder 版本。如果有多张 GPU，设置 `OLLAMA_GPU_LAYERS` 环境变量可以优化推理性能。与云端 API 相比，本地模型的优势在于数据不出本机、无网络依赖、无调用计费；代价则是模型能力上限和并发处理能力有限。根据实际场景灵活选择，才是正解。
