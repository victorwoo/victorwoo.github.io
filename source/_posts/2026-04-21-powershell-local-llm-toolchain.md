---
layout: post
date: 2026-04-21 08:00:00
updated: 2026-04-21 08:00:00
title: "PowerShell 技能连载 - 本地 LLM 工具链"
description: PowerTip of the Day - Local LLM Toolchain in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
- tooling
---

_适用于 PowerShell 7.0 及以上版本，需要 Ollama 或 LM Studio_

<!-- more -->

## 背景引入

随着大语言模型（LLM）的快速发展，越来越多的开发者希望在自己的工作站上运行本地模型，以满足数据隐私、离线场景和低延迟的需求。Ollama 和 LM Studio 是目前最流行的两个本地 LLM 运行工具，它们都提供了兼容 OpenAI 格式的 REST API，可以方便地从任何编程语言调用。

PowerShell 作为 Windows 和跨平台运维的核心脚本语言，天然适合充当本地 LLM 的"胶水层"。通过 PowerShell 调用本地模型 API，我们可以将 AI 能力无缝嵌入到日常运维脚本、日志分析、文档处理等任务中，而无需将敏感数据发送到云端。

本文将介绍如何用 PowerShell 构建完整的本地 LLM 工具链，包括模型管理与对话接口、RAG 本地知识库，以及 AI 辅助运维工具三个核心场景。所有代码均基于本地 API，不依赖任何云服务。

## Ollama API 集成

Ollama 提供了简洁的 REST API，默认监听 `http://localhost:11434`。下面的模块封装了模型列表查询、对话生成和流式输出等常用操作，可以作为日常脚本的基础工具集。

```powershell
function Get-OllamaModel {
    <# 获取本地已安装的模型列表 #>
    $response = Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' -Method Get
    $response.models | ForEach-Object {
        [PSCustomObject]@{
            Name       = $_.name
            SizeMB     = [math]::Round($_.size / 1MB, 1)
            ModifiedAt = $_.modified_at
            Family     = $_.details.family
            Parameter  = $_.details.parameter_size
        }
    } | Sort-Object Name | Format-Table -AutoSize
}

function Invoke-OllamaChat {
    <#
    .SYNOPSIS
        向本地 Ollama 模型发送对话请求
    .PARAMETER Model
        模型名称，如 qwen2.5:7b、llama3.1:8b
    .PARAMETER Messages
        消息数组，每条包含 role 和 content
    .PARAMETER Stream
        是否启用流式输出（默认 $false）
    .PARAMETER Temperature
        生成温度，0.0 到 1.0 之间
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Model,

        [Parameter(Mandatory)]
        [hashtable[]]$Messages,

        [switch]$Stream,

        [ValidateRange(0.0, 1.0)]
        [double]$Temperature = 0.7
    )

    $body = @{
        model      = $Model
        messages   = $Messages
        stream     = $Stream.IsPresent
        options    = @{
            temperature = $Temperature
        }
    } | ConvertTo-Json -Depth 5

    if ($Stream) {
        # 流式输出：逐行读取 SSE 响应
        $request = [System.Net.Http.HttpRequestMessage]::new(
            [System.Net.Http.HttpMethod]::Post,
            'http://localhost:11434/api/chat'
        )
        $request.Content = [System.Net.Http.StringContent]::new(
            $body, [System.Text.Encoding]::UTF8, 'application/json'
        )

        $client = [System.Net.Http.HttpClient]::new()
        $response = $client.Send($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
        $reader = [System.IO.StreamReader]::new($response.Content.ReadAsStream())

        $fullResponse = [System.Text.StringBuilder]::new()
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            if ($line) {
                $chunk = $line | ConvertFrom-Json
                if ($chunk.message.content) {
                    Write-Host $chunk.message.content -NoNewline
                    [void]$fullResponse.Append($chunk.message.content)
                }
                if ($chunk.done) { break }
            }
        }
        Write-Host ''
        $reader.Close()
        $client.Dispose()
        return $fullResponse.ToString()
    }
    else {
        $result = Invoke-RestMethod -Uri 'http://localhost:11434/api/chat' `
            -Method Post -Body $body -ContentType 'application/json'
        return $result.message.content
    }
}

# 用法示例：查看已安装模型
Get-OllamaModel

# 用法示例：单轮对话
$messages = @(
    @{ role = 'system'; content = '你是一个 PowerShell 专家，回答简洁精准。' }
    @{ role = 'user';   content = '如何获取系统中占用磁盘最大的 10 个目录？' }
)

$answer = Invoke-OllamaChat -Model 'qwen2.5:7b' -Messages $messages -Temperature 0.3
Write-Host "`n--- 模型回复 ---`n$answer"
```

执行结果示例：

```
Name              SizeMB   ModifiedAt               Family   Parameter
----              ------   ----------               ------   ---------
llama3.1:8b       4661.2   2026-04-18T10:30:00Z     llama    8B
qwen2.5:7b        4368.5   2026-04-20T14:22:00Z     qwen2    7B
deepseek-r1:7b    4520.8   2026-04-15T09:11:00Z     qwen2    7B
nomic-embed-text  274.1    2026-04-10T08:00:00Z     nomic    136M

--- 模型回复 ---

可以使用以下 PowerShell 命令获取占用磁盘最大的 10 个目录：

Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{ Path = $_.FullName; SizeMB = [math]::Round($size/1MB, 2) }
    } | Sort-Object SizeMB -Descending | Select-Object -First 10
```

## RAG 本地知识库

检索增强生成（RAG）是将本地文档作为上下文注入 LLM 的关键技术。下面的实现包含文档切片、向量化存储和检索查询三个步骤，完全使用本地模型（`nomic-embed-text` 做嵌入，对话模型做生成），无需外部服务。

```powershell
class LocalVectorStore {
    <# 本地向量存储，用于 RAG 检索 #>
    [System.Collections.Generic.List[hashtable]]$Documents

    LocalVectorStore() {
        $this.Documents = [System.Collections.Generic.List[hashtable]]::new()
    }

    [void] AddChunk([string]$Content, [string]$Source, [double[]]$Embedding) {
        $this.Documents.Add(@{
            content  = $Content
            source   = $Source
            embedding = $Embedding
        })
    }

    [double] CosineSimilarity([double[]]$A, [double[]]$B) {
        $dot = 0.0; $normA = 0.0; $normB = 0.0
        for ($i = 0; $i -lt $A.Count; $i++) {
            $dot += $A[$i] * $B[$i]
            $normA += $A[$i] * $A[$i]
            $normB += $B[$i] * $B[$i]
        }
        if ($normA -eq 0 -or $normB -eq 0) { return 0 }
        return $dot / ([math]::Sqrt($normA) * [math]::Sqrt($normB))
    }

    [hashtable[]] Search([double[]]$QueryEmbedding, [int]$TopK = 3) {
        return $this.Documents | ForEach-Object {
            [PSCustomObject]@{
                Content    = $_.content
                Source     = $_.source
                Similarity = $this.CosineSimilarity($QueryEmbedding, $_.embedding)
            }
        } | Sort-Object Similarity -Descending | Select-Object -First $TopK |
            ForEach-Object { @{ content = $_.Content; source = $_.Source; score = $_.Similarity } }
    }
}

function Get-LocalEmbedding {
    param([string]$Text)
    $body = @{ model = 'nomic-embed-text'; prompt = $Text } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri 'http://localhost:11434/api/embeddings' `
        -Method Post -Body $body -ContentType 'application/json'
    return $result.embedding
}

function Split-Document {
    param(
        [string]$Content,
        [int]$ChunkSize = 500,
        [int]$Overlap = 50
    )
    $chunks = [System.Collections.Generic.List[string]]::new()
    $words = $Content -split '\s+'
    $i = 0
    while ($i -lt $words.Count) {
        $end = [math]::Min($i + $ChunkSize, $words.Count)
        $chunkText = ($words[$i..($end - 1)] -join ' ')
        [void]$chunks.Add($chunkText)
        $i += $ChunkSize - $Overlap
    }
    return $chunks
}

function New-RAGIndex {
    <# 从指定目录的文档构建 RAG 索引 #>
    param(
        [string]$Path = '.\docs',
        [int]$ChunkSize = 500
    )

    $store = [LocalVectorStore]::new()
    $files = Get-ChildItem -Path $Path -Include '*.md','*.txt' -Recurse

    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $chunks = Split-Document -Content $content -ChunkSize $ChunkSize
        $chunkIndex = 0
        foreach ($chunk in $chunks) {
            $embedding = Get-LocalEmbedding -Text $chunk
            $store.AddChunk($chunk, "$($file.Name)#chunk-$chunkIndex", $embedding)
            $chunkIndex++
        }
        Write-Host "已索引: $($file.Name) ($($chunks.Count) 个切片)" -ForegroundColor Cyan
    }
    Write-Host "索引完成，共 $($store.Documents.Count) 个文档切片" -ForegroundColor Green
    return $store
}

function Invoke-RAGQuery {
    <# 基于 RAG 索引进行检索增强查询 #>
    param(
        [LocalVectorStore]$Store,
        [string]$Question,
        [string]$Model = 'qwen2.5:7b',
        [int]$TopK = 3
    )

    $queryEmbedding = Get-LocalEmbedding -Text $Question
    $results = $Store.Search($queryEmbedding, $TopK)

    $context = ($results | ForEach-Object {
        "【来源: $($_.source) | 相关度: $($_.score):N3】`n$($_.content)"
    }) -join "`n`n---`n`n"

    $messages = @(
        @{
            role    = 'system'
            content = '根据以下参考资料回答用户问题。如果资料中没有相关信息，请明确说明。'
        }
        @{
            role    = 'user'
            content = "参考资料：`n$context`n`n问题：$Question"
        }
    )

    Write-Host "`n检索到 $($results.Count) 条相关文档:" -ForegroundColor Yellow
    $results | ForEach-Object {
        Write-Host "  - $($_.source) (相关度: $($_.score):N3)" -ForegroundColor DarkGray
    }

    return Invoke-OllamaChat -Model $Model -Messages $messages -Temperature 0.2
}

# 用法示例：构建索引并查询
$store = New-RAGIndex -Path '.\knowledge-base'
$answer = Invoke-RAGQuery -Store $store -Question '公司的密码策略要求是什么？'
Write-Host "`n$answer"
```

执行结果示例：

```
已索引: security-policy.md (12 个切片)
已索引: operations-guide.md (8 个切片)
已索引: network-diagram.md (5 个切片)
索引完成，共 25 个文档切片

检索到 3 条相关文档:
  - security-policy.md#chunk-2 (相关度: 0.892)
  - security-policy.md#chunk-7 (相关度: 0.856)
  - operations-guide.md#chunk-1 (相关度: 0.743)

根据安全策略文档，公司密码策略要求如下：
1. 密码长度不少于 14 个字符
2. 必须包含大写字母、小写字母、数字和特殊字符中的至少三类
3. 密码有效期 90 天，不可重复最近 12 次使用过的密码
4. 账户锁定策略：连续 5 次输入错误后锁定 30 分钟
5. 管理员账户必须启用多因素认证（MFA）
```

## AI 辅助运维工具

将本地 LLM 与 PowerShell 运维脚本结合，可以构建智能化的日志分析、命令推荐和错误诊断工具。下面这个模块展示了几个实用的运维场景。

```powershell
function Invoke-AILogAnalysis {
    <# 使用本地 LLM 分析系统日志 #>
    param(
        [string]$LogPath = 'C:\Windows\System32\winevt\Logs\System.evtx',
        [int]$MaxEvents = 50,
        [string]$Model = 'qwen2.5:7b'
    )

    Write-Host "正在读取最近的 $MaxEvents 条事件日志..." -ForegroundColor Cyan
    $events = Get-WinEvent -Path $LogPath -MaxEvents $MaxEvents -ErrorAction SilentlyContinue

    if (-not $events) {
        $events = Get-WinEvent -LogName System -MaxEvents $MaxEvents
    }

    $errorEvents = $events | Where-Object { $_.Level -le 3 } |
        Select-Object TimeCreated, Id, LevelDisplayName, Message |
        Format-Table -AutoSize | Out-String

    $prompt = @"
以下是最近的事件日志（仅含错误和警告）：

$errorEvents

请分析以下内容：
1. 是否存在异常模式或重复性错误
2. 可能的根因分析
3. 推荐的处理步骤
"@

    $messages = @(
        @{ role = 'system'; content = '你是一位资深的 Windows 系统管理员，擅长日志分析和故障排查。' }
        @{ role = 'user';   content = $prompt }
    )

    return Invoke-OllamaChat -Model $Model -Messages $messages -Temperature 0.3
}

function Get-AICommandSuggestion {
    <# 根据自然语言描述推荐 PowerShell 命令 #>
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [string]$Model = 'qwen2.5:7b'
    )

    $messages = @(
        @{
            role    = 'system'
            content = '你是一个 PowerShell 命令助手。根据用户的自然语言描述，给出 1-3 个 PowerShell 命令方案。每个方案包含命令、参数说明和使用场景。只返回 PowerShell 代码和简短说明。'
        }
        @{
            role    = 'user'
            content = $Description
        }
    )

    return Invoke-OllamaChat -Model $Model -Messages $messages -Temperature 0.4
}

function Repair-AIScriptError {
    <# 使用本地 LLM 诊断和修复脚本错误 #>
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent,

        [Parameter(Mandatory)]
        [string]$ErrorMessage,

        [string]$Model = 'qwen2.5:7b'
    )

    $messages = @(
        @{
            role    = 'system'
            content = '你是一个 PowerShell 调试专家。分析脚本代码和错误信息，给出问题原因和修复后的完整脚本。'
        }
        @{
            role    = 'user'
            content = "脚本代码：`n$ScriptContent`n`n错误信息：`n$ErrorMessage"
        }
    )

    return Invoke-OllamaChat -Model $Model -Messages $messages -Temperature 0.2
}

# 用法示例 1：日志分析
$analysis = Invoke-AILogAnalysis -MaxEvents 100
Write-Host $analysis

# 用法示例 2：命令推荐
$suggestion = Get-AICommandSuggestion -Description '查找过去 24 小时内被修改的大于 100MB 的文件'
Write-Host $suggestion

# 用法示例 3：脚本错误修复
$badScript = @'
Get-Process | Where-Object { $_.WorkingSet -gt 100MB } | Select Name, CPU
'@

$errorMsg = 'Cannot compare "System.Byte[]" to "System.Int32"'

$fix = Repair-AIScriptError -ScriptContent $badScript -ErrorMessage $errorMsg
Write-Host $fix
```

执行结果示例：

```
正在读取最近的 100 条事件日志...

## 日志分析报告

### 异常模式
1. **重复性磁盘警告**：过去 2 小时内出现 15 次 Disk 警告（Event ID 51），
   指向磁盘 \Device\Harddisk1\DR1，表明可能存在磁盘硬件问题。
2. **服务异常终止**：W32Time 服务在 04:30 和 05:15 两次意外终止（Event ID 7034）。

### 根因分析
- 磁盘警告可能与坏道或 SATA 线缆松动有关
- 时间服务崩溃通常与网络连接中断相关

### 推荐处理步骤
1. 立即运行 `chkdsk /r` 检查磁盘健康状态
2. 使用 `smartctl -a /dev/sda` 查看 SMART 信息
3. 检查 W32Time 服务依赖的网络连接
4. 运行 `w32tm /resync` 重新同步时间
```

```
## 推荐方案

### 方案一：使用 Get-ChildItem
Get-ChildItem -Path C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 100MB -and $_.LastWriteTime -gt (Get-Date).AddHours(-24) } |
    Select-Object FullName, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime |
    Sort-Object SizeMB -Descending

适用于全盘扫描，结果详细但速度较慢。
```

## 注意事项

1. **模型选择与硬件匹配**：7B 参数模型至少需要 8GB 显存或 16GB 内存，13B 模型建议 16GB 以上显存。使用 `ollama list` 查看已安装模型，根据硬件配置选择合适的模型大小，避免因内存不足导致推理速度过慢或崩溃。

2. **API 兼容性**：Ollama 和 LM Studio 都兼容 OpenAI API 格式，但端口号不同（Ollama 默认 11434，LM Studio 默认 1234）。切换工具时需要修改 URI 前缀，建议将基础 URL 配置为变量或环境变量，便于灵活切换。

3. **RAG 的切片策略**：文档切片大小直接影响检索质量。过大的切片包含过多无关信息，过小的切片丢失上下文。对于技术文档建议 300-500 词，对于日志文件建议按时间窗口切分，每片保留完整的上下文信息。

4. **流式输出与超时处理**：长时间推理可能超过 `Invoke-RestMethod` 的默认超时。流式输出可以避免长时间等待无响应，但需要手动处理 SSE 数据流。建议为非流式调用设置 `-TimeoutSec 120` 或更长的超时值。

5. **敏感数据保护**：虽然使用本地模型避免了数据外传，但仍需注意日志中可能记录 API 请求内容。在生产环境中建议禁用 PowerShell 的脚本块日志记录（`ScriptBlockLogging`），并定期清理 Ollama 的会话历史。

6. **模型回复的不确定性**：LLM 生成的代码和建议可能存在错误。对于运维操作（特别是破坏性命令），务必先在测试环境验证，不要直接将 AI 生成的命令粘贴到生产终端执行。建议加入 `-WhatIf` 参数进行预检。
