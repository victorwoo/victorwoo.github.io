---
layout: post
date: 2026-04-01 08:00:00
title: "PowerShell 技能连载 - AI Agent 自动化框架"
description: PowerTip of the Day - AI Agent Automation Framework in PowerShell
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
- agent
- openai
- automation
---

_适用于 PowerShell 7.0 及以上版本_

AI Agent（智能代理）是当前大语言模型应用的热门方向。与传统的"单次问答"不同，Agent 能够自主规划任务步骤、调用外部工具、根据执行结果进行推理，最终完成复杂目标。对于系统运维工程师来说，这意味着可以将 LLM 的理解能力与 PowerShell 强大的系统管理能力结合起来，构建出真正"懂意图"的自动化框架。

PowerShell 作为 Windows/Linux/macOS 通用的脚本语言，天生具备丰富的系统管理 cmdlet（如文件操作、进程管理、网络请求、注册表读写等），这些都可以作为 Agent 的"工具"暴露给 LLM。通过精心设计的工具调用协议，Agent 可以根据用户的自然语言描述，自动选择合适的命令并执行。

本文将分三个部分逐步构建一个轻量级 AI Agent 框架：首先实现与 LLM API 的对话集成，然后定义工具调用机制，最后实现 ReAct（Reasoning + Acting）循环，使 Agent 具备多步推理和自主执行的能力。

## LLM API 集成

Agent 的核心是语言模型。我们首先封装一个通用的 LLM 调用函数，支持 OpenAI 兼容的 API（包括 OpenAI 官方、Azure OpenAI、以及 Ollama 等本地部署的模型）。该函数负责构建对话上下文、发送请求并解析响应。

```powershell
function Invoke-LLMChat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Messages,

        [Parameter()]
        [string]$Model = 'gpt-4o-mini',

        [Parameter()]
        [string]$BaseUrl = 'https://api.openai.com/v1',

        [Parameter()]
        [string]$ApiKey = $env:OPENAI_API_KEY,

        [Parameter()]
        [double]$Temperature = 0.3,

        [Parameter()]
        [array]$Tools
    )

    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer $ApiKey"
    }

    $body = @{
        model       = $Model
        messages    = $Messages
        temperature = $Temperature
    }

    if ($Tools) {
        $body['tools'] = $Tools
        $body['tool_choice'] = 'auto'
    }

    $uri = "$BaseUrl/chat/completions"
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)

    return $response.choices[0].message
}

# 构建系统提示词，定义 Agent 的角色和行为规范
$systemPrompt = @"
你是一个 PowerShell 运维 Agent。你可以使用提供的工具来执行系统管理任务。
请根据用户的请求，选择合适的工具进行操作。每次只调用一个工具。
如果任务需要多个步骤，请逐步完成。操作完成后请给出简洁的总结。
"@

# 初始化对话历史
$script:conversationHistory = @(
    @{ role = 'system'; content = $systemPrompt }
)
```

上面的代码定义了 `Invoke-LLMChat` 函数，它接受对话消息数组、模型名称和可选的工具定义。通过 `$env:OPENAI_API_KEY` 环境变量读取 API 密钥，方便切换不同的 API 提供商。

执行结果示例：

```text
PS> Invoke-LLMChat -Messages @(@{role='user';content='你好'}) -Model 'gpt-4o-mini'

role    : assistant
content : 你好！我是 PowerShell 运维 Agent，可以帮助你管理系统。请问有什么需要？
```

## 工具调用框架

接下来定义 Agent 可用的工具集。每个工具包含名称、描述和参数定义（遵循 JSON Schema 格式），以及对应的 PowerShell 执行函数。当 LLM 决定调用某个工具时，我们会解析其返回的函数调用请求，执行对应的 PowerShell 命令，并将结果反馈给模型。

```powershell
# 定义可用的工具列表（OpenAI function calling 格式）
$script:agentTools = @(
    @{
        type     = 'function'
        function = @{
            name        = 'get_system_info'
            description = '获取当前系统的基本信息，包括操作系统版本、CPU、内存、磁盘使用情况'
            parameters  = @{
                type       = 'object'
                properties = @{
                    details = @{
                        type        = 'boolean'
                        description = '是否返回详细信息'
                    }
                }
            }
        }
    }
    @{
        type     = 'function'
        function = @{
            name        = 'list_processes'
            description = '列出当前运行的进程，可按名称筛选并排序'
            parameters  = @{
                type       = 'object'
                properties = @{
                    name      = @{
                        type        = 'string'
                        description = '按进程名称筛选（支持通配符）'
                    }
                    top       = @{
                        type        = 'integer'
                        description = '返回前 N 个结果，默认 10'
                    }
                    sortBy    = @{
                        type        = 'string'
                        enum        = @('CPU', 'Memory', 'Name')
                        description = '排序依据'
                    }
                }
            }
        }
    }
    @{
        type     = 'function'
        function = @{
            name        = 'read_file_content'
            description = '读取指定路径的文件内容'
            parameters  = @{
                type       = 'object'
                properties = @{
                    path     = @{
                        type        = 'string'
                        description = '文件路径'
                    }
                    lastN    = @{
                        type        = 'integer'
                        description = '只读取最后 N 行'
                    }
                }
                required = @('path')
            }
        }
    }
)

# 工具执行分发器：根据工具名调用对应的 PowerShell 实现
function Invoke-AgentTool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ToolName,

        [Parameter(Mandatory)]
        [hashtable]$Arguments
    )

    switch ($ToolName) {
        'get_system_info' {
            $os = Get-CimInstance Win32_OperatingSystem
            $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
            $disks = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3'

            $result = @{
                OS         = $os.Caption
                Version    = $os.Version
                CPU        = $cpu.Name
                TotalMemGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                FreeMemGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                Disks      = $disks | ForEach-Object {
                    @{
                        Drive     = $_.DeviceID
                        FreeGB    = [math]::Round($_.FreeSpace / 1GB, 2)
                        TotalGB   = [math]::Round($_.Size / 1GB, 2)
                        UsedPct   = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100, 1)
                    }
                }
            }
            return ($result | ConvertTo-Json -Depth 5)
        }

        'list_processes' {
            $procs = Get-Process
            if ($Arguments.name) {
                $procs = $procs | Where-Object { $_.Name -like $Arguments.name }
            }
            $sortField = if ($Arguments.sortBy -eq 'Memory') { 'WorkingSet64' }
                         elseif ($Arguments.sortBy -eq 'CPU') { 'CPU' }
                         else { 'Name' }
            $top = if ($Arguments.top) { $Arguments.top } else { 10 }

            $result = $procs |
                Sort-Object -Property $sortField -Descending |
                Select-Object -First $top |
                ForEach-Object {
                    @{
                        Name       = $_.Name
                        PID        = $_.Id
                        CPU_s      = [math]::Round($_.CPU, 2)
                        MemoryMB   = [math]::Round($_.WorkingSet64 / 1MB, 2)
                    }
                }
            return ($result | ConvertTo-Json -Depth 3)
        }

        'read_file_content' {
            $path = $Arguments.path
            if (-not (Test-Path $path)) {
                return "错误：文件 '$path' 不存在"
            }
            $content = Get-Content $path -Encoding UTF8
            if ($Arguments.lastN -gt 0) {
                $content = $content | Select-Object -Last $Arguments.lastN
            }
            return ($content -join "`n")
        }

        default {
            return "错误：未知工具 '$ToolName'"
        }
    }
}
```

这段代码定义了三个实用工具：`get_system_info` 获取系统状态、`list_processes` 管理进程、`read_file_content` 读取文件。`Invoke-AgentTool` 函数作为分发器，根据工具名路由到对应的实现逻辑。

执行结果示例：

```text
PS> Invoke-AgentTool -ToolName 'get_system_info' -Arguments @{}

{
  "OS": "Microsoft Windows 11 Pro",
  "Version": "10.0.26100",
  "CPU": "AMD Ryzen 9 7950X",
  "TotalMemGB": 31.73,
  "FreeMemGB": 14.25,
  "Disks": [
    { "Drive": "C:", "FreeGB": 234.5, "TotalGB": 512.0, "UsedPct": 54.2 },
    { "Drive": "D:", "FreeGB": 876.1, "TotalGB": 1024.0, "UsedPct": 14.4 }
  ]
}
```

## ReAct 循环实现

现在将 LLM 和工具调用结合起来，实现 ReAct（Reasoning + Acting）循环。Agent 在每一步都会思考当前状态、选择一个工具执行、观察执行结果，然后决定下一步行动，直到任务完成或达到最大步数限制。

```powershell
function Start-AgentReAct {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserQuery,

        [Parameter()]
        [int]$MaxSteps = 10,

        [Parameter()]
        [string]$Model = 'gpt-4o-mini',

        [Parameter()]
        [string]$BaseUrl = 'https://api.openai.com/v1',

        [Parameter()]
        [switch]$Verbose
    )

    # 初始化对话上下文
    $history = [System.Collections.ArrayList]::new()
    [void]$history.Add(@{ role = 'system'; content = $systemPrompt })
    [void]$history.Add(@{ role = 'user'; content = $UserQuery })

    Write-Host "`n=== Agent 启动 ===" -ForegroundColor Cyan
    Write-Host "任务: $UserQuery`n" -ForegroundColor Yellow

    for ($step = 1; $step -le $MaxSteps; $step++) {
        Write-Host "--- 步骤 $step/$MaxSteps ---" -ForegroundColor DarkGray

        # 调用 LLM 进行推理
        $response = Invoke-LLMChat -Messages $history -Model $Model `
            -BaseUrl $BaseUrl -Tools $script:agentTools

        # 如果模型直接返回文本回复（没有工具调用），说明任务已完成
        if (-not $response.tool_calls) {
            Write-Host "`n=== Agent 完成 ===" -ForegroundColor Green
            Write-Host "最终回复: $($response.content)" -ForegroundColor White
            return $response.content
        }

        # 将助手消息（含工具调用请求）加入历史
        [void]$history.Add($response)

        # 处理每个工具调用
        foreach ($toolCall in $response.tool_calls) {
            $toolName = $toolCall.function.name
            $toolArgs = $toolCall.function.arguments | ConvertFrom-Json -AsHashtable

            if ($Verbose) {
                Write-Host "调用工具: $toolName" -ForegroundColor Magenta
                Write-Host "参数: $($toolArgs | ConvertTo-Json -Compress)" -ForegroundColor DarkGray
            }

            # 执行工具
            $toolOutput = Invoke-AgentTool -ToolName $toolName -Arguments $toolArgs

            if ($Verbose) {
                $preview = if ($toolOutput.Length -gt 200) {
                    $toolOutput.Substring(0, 200) + '...'
                } else {
                    $toolOutput
                }
                Write-Host "结果: $preview" -ForegroundColor DarkGray
            }

            # 将工具执行结果反馈给模型
            [void]$history.Add(@{
                role             = 'tool'
                tool_call_id     = $toolCall.id
                content          = $toolOutput
            })
        }
    }

    Write-Host "`n=== 达到最大步数限制 ===" -ForegroundColor Red
    Write-Host "Agent 未能在 $MaxSteps 步内完成任务。" -ForegroundColor Red
}
```

这段代码实现了完整的 ReAct 循环。每次迭代中，Agent 先向 LLM 发送当前对话历史和可用工具列表，LLM 决定是直接回复还是调用工具。如果调用了工具，执行后将结果追加到对话历史中，继续下一轮推理。

执行结果示例：

```text
PS> Start-AgentReAct -UserQuery '检查系统磁盘空间是否充足，如果 C 盘使用率超过 80%，列出占用内存最多的 5 个进程' -Verbose

=== Agent 启动 ===
任务: 检查系统磁盘空间是否充足，如果 C 盘使用率超过 80%，列出占用内存最多的 5 个进程

--- 步骤 1/10 ---
调用工具: get_system_info
参数: {"details":true}
结果: {"OS":"Microsoft Windows 11 Pro","Version":"10.0.26100","CPU":"AMD Ryzen 9 7950X",...

--- 步骤 2/10 ---
调用工具: list_processes
参数: {"sortBy":"Memory","top":5}
结果: [{"Name":"chrome","PID":12804,"CPU_s":342.56,"MemoryMB":812.34},...

--- 步骤 3/10 ---

=== Agent 完成 ===
最终回复: 系统磁盘状态良好。C 盘使用率 54.2%，未超过 80% 阈值。
不过我仍然为你列出了占用内存最多的 5 个进程：
1. chrome (PID 12804) - 812.3 MB
2. Code (PID 9216) - 654.1 MB
3. msedge (PID 4452) - 423.7 MB
4. PowerShell (PID 7780) - 287.4 MB
5. docker (PID 3308) - 198.2 MB
```

## 注意事项

1. **API 密钥安全**：切勿将 API 密钥硬编码在脚本中，应通过环境变量（如 `$env:OPENAI_API_KEY`）或 Azure Key Vault 等密钥管理服务获取，避免密钥泄露。

2. **工具执行权限**：Agent 调用的工具具有与运行脚本相同的权限。在生产环境中，务必对工具实现添加权限校验和白名单机制，防止 Agent 执行危险操作（如删除关键文件、修改系统配置）。

3. **循环步数限制**：ReAct 循环必须设置 `MaxSteps` 上限，防止 LLM 陷入无限循环。建议根据任务复杂度设置为 5-15 步，并在达到上限时给出明确的告警信息。

4. **本地模型支持**：如果使用 Ollama 等本地模型，只需将 `BaseUrl` 改为 `http://localhost:11434/v1`，`ApiKey` 设为 `ollama` 即可。但本地模型的工具调用能力可能不如 GPT-4 系列稳定，建议充分测试。

5. **错误处理与重试**：网络请求可能因超时或限流失败。建议在 `Invoke-LLMChat` 中添加指数退避重试逻辑，并对工具执行结果进行异常捕获，将错误信息反馈给 Agent 以便自我修正。

6. **对话历史管理**：长对话会消耗大量 Token。实际使用时应实现滑动窗口或摘要机制，在保留关键上下文的同时控制历史消息长度，降低 API 调用成本。
