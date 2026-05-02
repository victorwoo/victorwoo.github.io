---
layout: post
date: 2026-04-22 08:00:00
updated: 2026-04-22 08:00:00
title: "PowerShell 技能连载 - Prompt Engineering 实践"
description: PowerTip of the Day - Prompt Engineering Practices in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
- prompt-engineering
- llm
- copilot
---

_适用于 PowerShell 7.0 及以上版本_

随着大语言模型（LLM）的快速普及，Prompt Engineering 已经成为运维工程师不可或缺的技能。在
PowerShell 生态中，我们可以将提示词工程与自动化脚本深度结合，构建出智能化的运维工具链。无论是在
Azure 资源管理、日志分析还是故障诊断场景中，精心设计的 Prompt 都能大幅提升 LLM 输出的准确性和可用性。

传统的运维脚本通常依赖固定逻辑处理已知场景，但面对模糊的故障描述或复杂的架构问题时往往力不从心。
通过 Prompt Engineering，我们可以让 LLM 理解系统上下文，生成符合 PowerShell 风格的命令和脚本，
甚至自动分析错误日志并给出修复建议。关键在于如何用结构化的方式管理与 LLM 的交互。

本文将从模板管理、结构化输出控制和运维 Copilot 实现三个层面，展示如何在 PowerShell 中系统化地
应用 Prompt Engineering 最佳实践。

## Prompt 模板管理

在生产环境中，我们通常需要维护多套 Prompt 模板来应对不同的运维场景。手动拼接字符串既容易出错，
也难以维护。下面是一个可复用的 Prompt 模板管理系统，支持变量替换和上下文管理：

```powershell
class PromptTemplate {
    [string]$Name
    [string]$Template
    [hashtable]$Variables = @{}
    [string]$SystemContext

    PromptTemplate([string]$Name, [string]$Template) {
        $this.Name = $Name
        $this.Template = $Template
    }

    [void] SetVariable([string]$Key, [object]$Value) {
        $this.Variables[$Key] = $Value
    }

    [void] SetSystemContext([string]$Context) {
        $this.SystemContext = $Context
    }

    [string] Render() {
        $rendered = $this.Template
        foreach ($key in $this.Variables.Keys) {
            $placeholder = "{{$key}}"
            $rendered = $rendered -replace [regex]::Escape($placeholder), $this.Variables[$key]
        }
        return $rendered
    }

    [hashtable] ToChatMessages() {
        $messages = @()
        if ($this.SystemContext) {
            $messages += @{
                role    = 'system'
                content = $this.SystemContext
            }
        }
        $messages += @{
            role    = 'user'
            content = $this.Render()
        }
        return @{ messages = $messages }
    }
}

# 创建运维场景的 Prompt 模板库
$templates = @{}

$templates['error-diagnosis'] = [PromptTemplate]::new(
    'error-diagnosis',
    '请分析以下 PowerShell 错误信息，给出可能的原因和修复建议。' +
    "`n`n错误类型：{ErrorType}" +
    "`n错误消息：{ErrorMessage}" +
    '`n发生环境：{Environment}'
)

$templates['script-generation'] = [PromptTemplate]::new(
    'script-generation',
    '请生成一个 PowerShell 脚本，要求如下：' +
    "`n目标：{Goal}" +
    "`n约束条件：{Constraints}" +
    "`n目标平台：{Platform}" +
    '`n请使用 PowerShell 7 兼容语法，包含错误处理和注释。'
)

# 设置系统上下文：定义 LLM 的角色和行为规范
$systemContext = @"
你是一位资深的 PowerShell 和 Azure 运维专家。
你的回答需要：
1. 使用 PowerShell 7 兼容语法
2. 包含完整的错误处理（try/catch/finally）
3. 遵循最佳实践（Approved Verbs、强类型、注释）
4. 输出可直接执行的脚本代码
"@

$templates['error-diagnosis'].SetSystemContext($systemContext)
$templates['script-generation'].SetSystemContext($systemContext)

# 使用模板：填充变量并渲染
$tpl = $templates['error-diagnosis']
$tpl.SetVariable('ErrorType', 'InvalidOperationException')
$tpl.SetVariable('ErrorMessage', 'Collection was modified; enumeration operation may not execute.')
$tpl.SetVariable('Environment', 'Windows Server 2022, PowerShell 7.4')

$renderedPrompt = $tpl.Render()
$chatPayload = $tpl.ToChatMessages()

Write-Host "=== 渲染后的 Prompt ===" -ForegroundColor Cyan
Write-Host $renderedPrompt
Write-Host "`n=== Chat API 载荷 ===" -ForegroundColor Cyan
$chatPayload | ConvertTo-Json -Depth 3
```

执行结果示例：

```text
=== 渲染后的 Prompt ===
请分析以下 PowerShell 错误信息，给出可能的原因和修复建议。

错误类型：InvalidOperationException
错误消息：Collection was modified; enumeration operation may not execute.
发生环境：Windows Server 2022, PowerShell 7.4

=== Chat API 载荷 ===
{
  "messages": [
    {
      "role": "system",
      "content": "你是一位资深的 PowerShell 和 Azure 运维专家。\n你的回答需要：\n1. 使用 PowerShell 7 兼容语法\n2. 包含完整的错误处理（try/catch/finally）\n3. 遵循最佳实践（Approved Verbs、强类型、注释）\n4. 输出可直接执行的脚本代码\n"
    },
    {
      "role": "user",
      "content": "请分析以下 PowerShell 错误信息，给出可能的原因和修复建议。\n\n错误类型：InvalidOperationException\n错误消息：Collection was modified; enumeration operation may not execute.\n发生环境：Windows Server 2022, PowerShell 7.4"
    }
  ]
}
```

## 结构化输出控制

LLM 返回自由文本虽然灵活，但在自动化流程中很难直接使用。通过精心设计 Prompt，我们可以
引导 LLM 输出结构化的 JSON，再由 PowerShell 解析为对象。下面展示如何实现输出控制、
Schema 校验和自动重试机制：

```powershell
function Invoke-StructuredCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserPrompt,

        [Parameter(Mandatory)]
        [string]$JsonSchema,

        [string]$Model = 'gpt-4o-mini',

        [int]$MaxRetries = 3,

        [string]$Endpoint = 'http://localhost:11434/v1/chat/completions'
    )

    # 构建系统提示词，强制 JSON 输出并给出 Schema
    $systemPrompt = @"
你是一个 PowerShell 运维助手。用户会提出运维相关的问题，你需要给出结构化的回答。

严格要求：
1. 只输出合法的 JSON，不要包含任何其他文字说明
2. 严格遵循以下 JSON Schema：
$JsonSchema
3. 不要输出 Markdown 代码块标记，直接输出 JSON
4. 字符串值使用 UTF-8 编码
"@

    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        $attempt++
        Write-Verbose "尝试第 $attempt 次..."

        $body = @{
            model       = $Model
            messages    = @(
                @{ role = 'system'; content = $systemPrompt },
                @{ role = 'user';   content = $UserPrompt }
            )
            temperature = 0.1
        } | ConvertTo-Json -Depth 5

        try {
            $response = Invoke-RestMethod -Uri $Endpoint -Method Post `
                -ContentType 'application/json' `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                -ErrorAction Stop

            $content = $response.choices[0].message.content.Trim()

            # 去除可能的 Markdown 代码块标记
            if ($content -match '^\x60{3}json?\s*([\s\S]*?)\x60{3}$') {
                $content = $Matches[1].Trim()
            }

            # 尝试解析 JSON
            $parsed = $content | ConvertFrom-Json -ErrorAction Stop

            Write-Verbose "JSON 解析成功"
            return [PSCustomObject]@{
                Success   = $true
                Data      = $parsed
                Raw       = $content
                Attempts  = $attempt
            }
        }
        catch {
            Write-Warning "第 $attempt 次尝试失败：$($_.Exception.Message)"
            if ($attempt -ge $MaxRetries) {
                return [PSCustomObject]@{
                    Success  = $false
                    Error    = $_.Exception.Message
                    Attempts = $attempt
                }
            }
            Start-Sleep -Milliseconds ($attempt * 500)
        }
    }
}

# 定义输出 Schema：服务器健康检查结果
$schema = @'
{
  "type": "object",
  "properties": {
    "server_name": { "type": "string" },
    "overall_status": { "type": "string", "enum": ["healthy", "warning", "critical"] },
    "checks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "item": { "type": "string" },
          "status": { "type": "string" },
          "detail": { "type": "string" },
          "recommendation": { "type": "string" }
        },
        "required": ["item", "status", "detail", "recommendation"]
      }
    },
    "summary": { "type": "string" }
  },
  "required": ["server_name", "overall_status", "checks", "summary"]
}
'@

$result = Invoke-StructuredCompletion -UserPrompt @'
WebSrv01 服务器状态：CPU 使用率 92%，内存剩余 2GB/32GB，
磁盘 C: 剩余 15%，事件日志中发现 37 个 Error 级别事件（过去 1 小时），
IIS 应用池 MyAppPool 已崩溃 3 次。
'@ -JsonSchema $schema -Verbose

if ($result.Success) {
    Write-Host "服务器：$($result.Data.server_name)" -ForegroundColor Cyan
    Write-Host "状态：$($result.Data.overall_status)" -ForegroundColor Yellow
    Write-Host "`n检查项："
    $result.Data.checks | Format-Table -Property item, status, detail -Wrap
    Write-Host "摘要：$($result.Data.summary)"
}
```

执行结果示例：

```text
详细: 尝试第 1 次...
详细: JSON 解析成功
服务器：WebSrv01
状态：critical

检查项：

item         status    detail
----         ------    ------
CPU 使用率   critical  持续 92%，远超 80% 阈值
内存使用     warning   剩余 2GB，接近耗尽
磁盘空间     warning   C: 盘仅剩 15%
事件日志     critical  1 小时内 37 个 Error 事件
IIS 应用池   critical  MyAppPool 已崩溃 3 次

摘要：WebSrv01 服务器处于 critical 状态，CPU 和 IIS 应用池问题最为紧急，
建议立即排查 CPU 占用进程并重启应用池。
```

## 运维 Copilot 实现

将前面两节的技术整合起来，我们可以构建一个实用的运维 Copilot 工具。它能够自动收集系统信息，
结合上下文回答运维问题，生成 PowerShell 命令，甚至诊断错误。下面是一个完整的实现：

```powershell
class OpsCopilot {
    [string]$Model
    [string]$Endpoint
    [hashtable]$Templates
    [string]$SystemInfo

    OpsCopilot([string]$Endpoint, [string]$Model) {
        $this.Endpoint = $Endpoint
        $this.Model = $Model
        $this.Templates = @{}
        $this.SystemInfo = $this.CollectSystemInfo()
        $this.RegisterTemplates()
    }

    [string] CollectSystemInfo() {
        $info = @{
            hostname     = $env:COMPUTERNAME
            os           = (Get-CimInstance Win32_OperatingSystem).Caption
            psVersion    = $PSVersionTable.PSVersion.ToString()
            dotnet       = [System.Environment]::Version.ToString()
            cpu          = (Get-CimInstance Win32_Processor).Name
            totalMemGB   = [math]::Round(
                (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1
            )
            drives       = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
                ForEach-Object {
                    @{
                        drive     = $_.DeviceID
                        freeGB    = [math]::Round($_.FreeSpace / 1GB, 1)
                        totalGB   = [math]::Round($_.Size / 1GB, 1)
                    }
                }
        }
        return ($info | ConvertTo-Json -Depth 3)
    }

    [void] RegisterTemplates() {
        $this.Templates['ask'] = @'
基于以下系统信息回答运维问题。

系统信息：
{SystemInfo}

问题：{Question}

请给出：
1. 问题分析
2. 具体的 PowerShell 命令或脚本
3. 注意事项
'@

        $this.Templates['diagnose'] = @'
基于以下系统信息诊断错误。

系统信息：
{SystemInfo}

错误详情：
{ErrorDetail}

请分析：
1. 错误的根本原因
2. 修复步骤（含 PowerShell 命令）
3. 预防措施
'@
    }

    [string] RenderTemplate([string]$TemplateName, [hashtable]$Vars) {
        $rendered = $this.Templates[$TemplateName]
        $rendered = $rendered -replace '\{SystemInfo\}', $this.SystemInfo
        foreach ($key in $Vars.Keys) {
            $rendered = $rendered -replace "\{$key\}", $Vars[$key]
        }
        return $rendered
    }

    [string] Chat([string]$UserMessage) {
        $systemPrompt = @"
你是一位精通 PowerShell 和 Windows Server 的运维专家。
当前系统环境：
$($this.SystemInfo)

回答要求：
- 优先使用 PowerShell 7 原生命令
- 脚本包含 try/catch 错误处理
- 给出可立即执行的命令
- 用中文回答
"@

        $body = @{
            model       = $this.Model
            messages    = @(
                @{ role = 'system'; content = $systemPrompt },
                @{ role = 'user';   content = $UserMessage }
            )
            temperature = 0.2
        } | ConvertTo-Json -Depth 5

        $response = Invoke-RestMethod -Uri $this.Endpoint -Method Post `
            -ContentType 'application/json' `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body))

        return $response.choices[0].message.content
    }

    [string] Ask([string]$Question) {
        $prompt = $this.RenderTemplate('ask', @{
            Question = $Question
        })
        return $this.Chat($prompt)
    }

    [string] Diagnose([string]$ErrorDetail) {
        $prompt = $this.RenderTemplate('diagnose', @{
            ErrorDetail = $ErrorDetail
        })
        return $this.Chat($prompt)
    }
}

# 初始化 Copilot（使用本地 Ollama 或远程 API）
$copilot = [OpsCopilot]::new('http://localhost:11434/v1/chat/completions', 'qwen3:8b')

# 示例 1：提出运维问题
Write-Host "=== 运维问答 ===" -ForegroundColor Cyan
$answer = $copilot.Ask('如何查找占用磁盘空间最大的前 10 个文件夹？')
Write-Host $answer

# 示例 2：诊断错误
Write-Host "`n=== 错误诊断 ===" -ForegroundColor Cyan
$diagnosis = $copilot.Diagnose(@"
执行 Get-EventLog -LogName Application -Newest 100 时报错：
"Requested registry access is not allowed"
当前以普通用户身份运行 PowerShell。
"@)
Write-Host $diagnosis
```

执行结果示例：

```text
=== 运维问答 ===
[问题分析]
在磁盘空间不足时，需要快速定位占用空间最大的目录，以便清理。

[PowerShell 命令]
使用以下命令查找 D: 盘中最大的 10 个文件夹：

    Get-ChildItem -Path 'D:\' -Directory -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            [PSCustomObject]@{
                Path   = $_.FullName
                SizeMB = [math]::Round($size / 1MB, 2)
            }
        } | Sort-Object SizeMB -Descending | Select-Object -First 10 |
        Format-Table -AutoSize

[注意事项]
1. 对整个盘扫描很慢，建议缩小搜索范围
2. 加 -ErrorAction SilentlyContinue 跳过无权限目录
3. 管道中计算大小是内存友好的方式

=== 错误诊断 ===
[根本原因]
Get-EventLog 需要管理员权限才能访问事件日志注册表项。以普通用户运行时，
会被拒绝访问。

[修复步骤]
# 方法 1：以管理员身份运行 PowerShell
Start-Process pwsh -Verb RunAs

# 方法 2（推荐）：改用 Get-WinEvent，它支持更精细的权限控制
Get-WinEvent -LogName 'Application' -MaxEvents 100

# 方法 3：仅查看有权限的日志
Get-WinEvent -ListLog '*' | Where-Object { $_.IsLogFullNameValid }

[预防措施]
1. 优先使用 Get-WinEvent 替代已过时的 Get-EventLog
2. 运维脚本中加入权限检查：
   if (-not ([Security.Principal.WindowsPrincipal]::new(
       [Security.Principal.WindowsIdentity]::GetCurrent()
       )).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       Write-Warning '建议以管理员身份运行此脚本'
   }
```

## 注意事项

1. **API 端点安全**：生产环境中调用 LLM API 时，务必使用 HTTPS 并通过环境变量或
   Azure Key Vault 管理 API 密钥，不要将密钥硬编码在脚本中。可以使用
   `ConvertFrom-SecureString` 或 `Get-Secret` 安全地获取凭据。

2. **Prompt 注入防护**：当 Prompt 中包含用户输入或外部数据时，要对内容进行清理，
   避免恶意指令注入。可以用 `-replace` 去除特殊字符，或对用户输入做白名单过滤。

3. **输出校验不可省略**：即使指定了 JSON Schema，LLM 仍可能输出不符合预期的内容。
   始终在解析前做格式检查，重试机制是生产环境的必要保障。建议设置合理的
   `$MaxRetries`（通常 3 次足够）。

4. **上下文长度管理**：收集系统信息时注意控制 Token 数量。对于大型环境（数百台服务器），
   先做摘要或筛选再传入 Prompt，避免超出模型的上下文窗口限制。可以用
   `($text | Measure-Object -Character).Characters` 估算 Token 消耗。

5. **模板版本管理**：将 Prompt 模板存储为独立的 JSON 或 YAML 文件，纳入 Git 版本控制。
   这样可以追踪模板变更对输出质量的影响，也方便团队成员协作。建议在模板中加入版本号和
   最后更新时间字段。

6. **本地模型优先**：对于包含敏感系统信息的运维场景，优先使用本地部署的模型（如 Ollama、
   vLLM）而非云端 API。这既降低了数据泄露风险，也减少了网络延迟对自动化流程的影响。
   如果必须使用云端 API，确保数据传输经过加密且符合公司的安全合规要求。
