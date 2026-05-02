---
layout: post
date: 2025-12-31 08:00:00
updated: 2025-12-31 08:00:00
title: "PowerShell 技能连载 - 2025 年度回顾与 2026 展望"
description: PowerTip of the Day - 2025 Year in Review and 2026 Outlook
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- best-practices
- office
- ai
- future
---

_适用于 PowerShell 5.1 及以上版本_

2025 年对 PowerShell 社区而言是里程碑式的一年。PowerShell 7.5 正式发布，全面拥抱 .NET 8 带来的性能提升与新 API，同时官方团队持续推动跨平台体验的统一。云原生、容器化和 GitOps 已经不再只是 buzzword，而是日常运维的基本范式，PowerShell 在其中扮演了越来越重要的胶水语言角色。

与此同时，AI 大模型的爆发深刻改变了自动化脚本的工作方式。从调用 OpenAI API 做日志分析，到用本地模型生成配置模板，再到 IDE 中的智能补全，AI 工具链已经深度融入 PowerShell 开发者的日常工作流。这一年我们见证了脚本编写方式从"查文档写代码"到"描述需求生成代码"的范式转变。

站在岁末年初的节点，本文将回顾 2025 年 PowerShell 生态的关键技术变化，梳理当前最实用的 AI 集成与云原生实战技巧，并展望 2026 年值得关注的趋势和学习方向。

<!-- more -->

## 2025 技术回顾

PowerShell 7.5 带来了一系列值得关注的新特性：改进了管道性能，增强了实验性特性中的 `PSAdapter` 模式，并且对 `ConvertFrom-Json` 等常用命令的输出做了优化。社区模块生态也蓬勃发展，`Pester` v6 正式发布，`PSFramework` 持续迭代。下面这段脚本盘点了一些关键模块的版本信息。

```powershell
# 2025 年 PowerShell 生态关键信息盘点
$psInfo = @{
    Version    = $PSVersionTable.PSVersion.ToString()
    Edition    = $PSVersionTable.PSEdition
    OS         = $PSVersionTable.OS
    Platform   = $PSVersionTable.Platform
}

Write-Host "=== PowerShell 运行环境 ===" -ForegroundColor Cyan
$psInfo.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0,-12} : {1}" -f $_.Key, $_.Value)
}

# 盘点已安装的关键模块版本
$keyModules = @(
    'Pester', 'PSFramework', 'PSScriptAnalyzer',
    'platyPS', 'InvokeBuild', 'PSChecker',
    'Microsoft.PowerShell.SecretManagement'
)

Write-Host "`n=== 关键模块版本 ===" -ForegroundColor Cyan
foreach ($mod in $keyModules) {
    $installed = Get-Module -ListAvailable -Name $mod -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
    if ($installed) {
        Write-Host ("  {0,-50} v{1}" -f $mod, $installed.Version)
    }
    else {
        Write-Host ("  {0,-50} [未安装]" -f $mod) -ForegroundColor DarkGray
    }
}

# 统计脚本文件数量（假设在项目目录中）
$projectDir = $PWD.Path
$scriptFiles = @(
    Get-ChildItem -Path $projectDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -Path $projectDir -Filter '*.psm1' -Recurse -ErrorAction SilentlyContinue
)
Write-Host ("`n=== 项目统计 ===" -ForegroundColor Cyan)
Write-Host ("  脚本文件总数 : {0}" -f $scriptFiles.Count)
Write-Host ("  代码行数合计 : {0}" -f (
    $scriptFiles | ForEach-Object { (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count } |
    Measure-Object -Sum | Select-Object -ExpandProperty Sum
))
```

执行结果示例：

```text
=== PowerShell 运行环境 ===
  Edition      : Core
  OS           : Unix 25.4.0
  Platform     : Unix
  Version      : 7.5.0

=== 关键模块版本 ===
  Pester                                             v6.0.4
  PSFramework                                        v1.12.0
  PSScriptAnalyzer                                   v1.23.0
  platyPS                                            v0.14.2
  InvokeBuild                                        v5.12.1
  PSChecker                                          [未安装]
  Microsoft.PowerShell.SecretManagement              v1.1.0

=== 项目统计 ===
  脚本文件总数 : 47
  代码行数合计 : 3216
```

## AI 集成与云原生实战

2025 年最显著的变化之一，是 AI API 的调用门槛大幅降低。PowerShell 原生的 `Invoke-RestMethod` 已经能轻松完成与大模型的交互，社区也涌现了 `PSOpenAI`、`Pode` 等优秀的封装模块。在云原生领域，`kubectl`、`docker` 与 PowerShell 的组合使用已经成为日常操作，跨平台执行也不再是障碍。

下面展示一段综合了 AI 调用和容器管理的实用脚本，帮助你快速理解当前主流的集成模式。

```powershell
# 示例 1：调用 OpenAI 兼容 API 进行日志异常分析
function Invoke-AILogAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogContent,

        [Parameter()]
        [string]$Endpoint = 'http://localhost:11434/v1/chat/completions',

        [Parameter()]
        [string]$Model = 'qwen2.5:7b',

        [Parameter()]
        [int]$MaxTokens = 1024
    )

    $body = @{
        model    = $Model
        messages = @(
            @{
                role    = 'system'
                content = '你是一名资深运维工程师，擅长分析系统日志中的异常模式。请用中文回复，列出关键异常和建议处理方案。'
            }
            @{
                role    = 'user'
                content = "请分析以下日志内容中的异常:`n`n$LogContent"
            }
        )
        max_tokens = $MaxTokens
        temperature = 0.3
    } | ConvertTo-Json -Depth 5

    $result = Invoke-RestMethod -Uri $Endpoint -Method Post -Body $body `
        -ContentType 'application/json; charset=utf-8' `
        -ErrorAction Stop

    return $result.choices[0].message.content
}

# 示例 2：跨平台容器状态巡检
function Get-ContainerHealthReport {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$DockerHost = 'localhost'
    )

    $containers = docker ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}|{{.Ports}}' 2>$null

    if (-not $containers) {
        Write-Warning "未检测到运行中的容器，请确认 Docker 服务是否已启动。"
        return
    }

    $report = $containers | ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            Name   = $parts[0]
            Status = $parts[1]
            Image  = $parts[2]
            Ports  = $parts[3]
            IsHealthy = $parts[1] -match '^Up'
        }
    }

    $report | Format-Table -AutoSize
    Write-Host ("健康容器: {0}/{1}" -f ($report | Where-Object IsHealthy).Count, $report.Count) `
        -ForegroundColor Green
}

# 执行巡检
Get-ContainerHealthReport
```

执行结果示例：

```text
Name            Status          Image              Ports       IsHealthy
----            ------          -----              -----       ---------
ollama          Up 3 hours      ollama/ollama      11434/tcp   True
open-webui      Up 3 hours      ghcr.io/open-webui 8080/tcp    True
postgres-db     Up 5 days       postgres:16        5432/tcp    True
redis-cache     Exited (0) 2h   redis:7            6379/tcp    False
nginx-proxy     Up 3 hours      nginx:alpine       80, 443     True

健康容器: 4/5
```

## 2026 技术展望与学习路线

展望 2026 年，几个清晰的趋势已经浮现：.NET 10 的发布将进一步提升 PowerShell 的运行时性能；AI Agent 模式（AI 自主调用工具、编排工作流）将深刻改变自动化脚本的编写方式；更多企业开始将 PowerShell DSC v3 与 Kubernetes Operator 结合，实现声明式基础设施管理。

以下脚本构建了一个个人技术雷达，帮助你梳理 2026 年的学习优先级。

```powershell
# 2026 年 PowerShell 技术雷达
$techRadar = @(
    [PSCustomObject]@{
        Category    = '核心语言'
        Technology  = 'PowerShell 7.6 / .NET 10'
        Priority    = '必须掌握'
        Reason      = '运行时性能提升、新 API 支持、源生成器优化'
    }
    [PSCustomObject]@{
        Category    = 'AI 集成'
        Technology  = 'AI Agent + Tool Calling'
        Priority    = '重点投入'
        Reason      = '大模型从辅助编码走向自主执行，需掌握 function calling 模式'
    }
    [PSCustomObject]@{
        Category    = '基础设施'
        Technology  = 'DSC v3 + K8s Operator'
        Priority    = '重点投入'
        Reason      = '声明式配置管理成为标准，DSC v3 与容器编排深度整合'
    }
    [PSCustomObject]@{
        Category    = '安全合规'
        Technology  = 'Crescendo + AppLocker'
        Priority    = '持续关注'
        Reason      = '零信任架构下脚本签名与执行策略管理更加重要'
    }
    [PSCustomObject]@{
        Category    = '测试工程'
        Technology  = 'Pester 6 + Test-Kitchen'
        Priority    = '必须掌握'
        Reason      = '基础设施即代码的测试覆盖度直接决定交付信心'
    }
    [PSCustomObject]@{
        Category    = '开发体验'
        Technology  = 'VS Code + Copilot + PSScriptAnalyzer'
        Priority    = '日常使用'
        Reason      = 'AI 辅助编码已成标配，结合静态分析确保质量'
    }
)

Write-Host "=== 2026 PowerShell 技术雷达 ===" -ForegroundColor Cyan
$techRadar | Format-Table -AutoSize -Wrap

# 学习路线建议
$learningPath = @{
    'Q1 (1-3月)'   = '深入学习 PowerShell 7.6 新特性，掌握 .NET 10 互操作'
    'Q2 (4-6月)'   = '实践 AI Agent + Tool Calling，构建自动化运维助手'
    'Q3 (7-9月)'   = '学习 DSC v3，结合 Kubernetes 实现声明式配置管理'
    'Q4 (10-12月)' = '完善 CI/CD 流水线，提升测试覆盖率和文档质量'
}

Write-Host "`n=== 推荐学习路线 ===" -ForegroundColor Cyan
$learningPath.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Host ("  {0} : {1}" -f $_.Key, $_.Value) -ForegroundColor Yellow
}

# 推荐学习资源
Write-Host "`n=== 推荐资源 ===" -ForegroundColor Cyan
$resources = @(
    '官方文档: learn.microsoft.com/powershell'
    '社区博客: devblogs.microsoft.com/powershell'
    '开源项目: github.com/PowerShell'
    '实战课程: PowerShell Conference EU 视频'
    'AI 实践: Ollama + Open WebUI 本地大模型环境'
)
$resources | ForEach-Object { Write-Host "  - $_" }
```

执行结果示例：

```text
=== 2026 PowerShell 技术雷达 ===

Category    Technology                   Priority  Reason
--------    -----------                  --------  ------
核心语言    PowerShell 7.6 / .NET 10     必须掌握  运行时性能提升、新 API 支持、源生成器优化
AI 集成     AI Agent + Tool Calling      重点投入  大模型从辅助编码走向自主执行...
基础设施    DSC v3 + K8s Operator        重点投入  声明式配置管理成为标准...
安全合规    Crescendo + AppLocker        持续关注  零信任架构下脚本签名与执行策略管理...
测试工程    Pester 6 + Test-Kitchen      必须掌握  基础设施即代码的测试覆盖度...
开发体验    VS Code + Copilot            日常使用  AI 辅助编码已成标配...

=== 推荐学习路线 ===
  Q1 (1-3月) : 深入学习 PowerShell 7.6 新特性，掌握 .NET 10 互操作
  Q2 (4-6月) : 实践 AI Agent + Tool Calling，构建自动化运维助手
  Q3 (7-9月) : 学习 DSC v3，结合 Kubernetes 实现声明式配置管理
  Q4 (10-12月): 完善 CI/CD 流水线，提升测试覆盖率和文档质量

=== 推荐资源 ===
  - 官方文档: learn.microsoft.com/powershell
  - 社区博客: devblogs.microsoft.com/powershell
  - 开源项目: github.com/PowerShell
  - 实战课程: PowerShell Conference EU 视频
  - AI 实践: Ollama + Open WebUI 本地大模型环境
```

## 注意事项

1. **保持版本同步**：生产环境建议统一使用 PowerShell 7.x LTS 版本，避免 5.1 和 7.x 的行为差异导致脚本在不同环境执行结果不一致。重点关注 `ConvertFrom-Json`、`Invoke-WebRequest` 等命令在两个版本间的差异。

2. **AI 辅助需要验证**：大模型生成的代码虽然越来越准确，但仍然会产生幻觉。关键逻辑必须人工审查，敏感操作（删除、修改配置）务必增加确认步骤。把 AI 当作高效的初稿生成器，而不是最终的代码审查者。

3. **安全基线不可忽视**：2025 年发生的多起供应链安全事件提醒我们，脚本的执行策略、模块来源验证和凭据管理必须作为常规检查项。定期使用 `Get-AuthenticodeSignature` 验证脚本签名，用 `Get-InstalledModule` 审计模块来源。

4. **测试先行**：无论是 AI 生成的代码还是手写脚本，上线前都应该通过 Pester 测试。2026 年建议将测试覆盖率目标设定为至少 80%，关键业务脚本达到 100%。`Pester 6` 的 `BeforeDiscovery` 和参数化测试功能值得深入学习。

5. **跨平台兼容意识**：随着 Linux 和 macOS 上 PowerShell 使用率持续增长，编写脚本时应养成使用 `Join-Path` 替代硬编码路径分隔符、避免依赖 Windows 专属命令的习惯。`$IsWindows`、`$IsLinux`、`$IsMacOS` 变量可以帮助你编写跨平台兼容的代码。

6. **持续学习与社区参与**：PowerShell 生态演进速度在加快，2026 年建议每周至少花 2 小时阅读 release notes 和社区博客。参与 GitHub Discussions、提交 Issue 或 PR 是跟上技术节奏的最佳方式。关注 `PowerShell Team` 的官方博客和年度路线图更新，可以让你的学习方向更加明确。
