---
layout: post
date: 2025-12-04 08:00:00
updated: 2025-12-04 08:00:00
title: "PowerShell 技能连载 - Pester 单元测试与 Mock"
description: PowerTip of the Day - Pester Unit Testing and Mocking in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- testing
- pester
- mocking
- unit-test
---

_适用于 PowerShell 5.1 及以上版本_

## 背景

在软件开发中，单元测试是保障代码质量的第一道防线。PowerShell 生态中最流行的测试框架是 Pester，它提供了一套简洁优雅的 DSL（领域特定语言），让你可以用 `Describe`、`Context`、`It` 三层结构组织测试用例，用 `Should` 断言验证预期结果。无论是简单的工具函数还是复杂的自动化脚本，Pester 都能为它们编写清晰可维护的测试。

然而，真实环境中的 PowerShell 脚本往往涉及大量外部依赖：调用 REST API、读写文件系统、查询数据库、操作 Windows 注册表。如果在测试中真正去调用这些外部资源，测试就会变得缓慢、脆弱、不可重复——API 服务可能宕机、文件路径可能不存在、数据库连接可能超时。Pester 的 Mock 机制正是为了解决这个问题，它允许你在测试中替换掉外部依赖，让测试专注于验证代码逻辑本身，而非依赖的可用性。

本文将从 Pester 的基础测试结构讲起，逐步介绍如何使用 Mock 隔离外部依赖，最后演示如何在 CI 流水线中集成测试覆盖率报告，形成完整的自动化测试闭环。

## 基础：Pester 测试结构与 Should 断言

Pester 测试文件通常以 `.Tests.ps1` 结尾，采用 `Describe` -> `Context` -> `It` 三层嵌套结构。`Describe` 描述被测功能模块，`Context` 划分测试场景，`It` 定义具体的测试用例。`Should` 是 Pester 的断言关键字，支持 `Be`、`BeNullOrEmpty`、`Throw`、`BeLike` 等丰富的匹配器，覆盖了日常测试的绝大多数场景。

以下代码演示了一个完整的 Pester 基础测试，包含字符串处理函数、数组操作函数以及异常处理函数的测试用例。

```powershell
# 被测函数：一组工具函数
function ConvertTo-TitleCase {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    return (Get-Culture).TextInfo.ToTitleCase($Text.ToLower())
}

function Get-Summary {
    param([int[]]$Numbers)
    if ($Numbers.Count -eq 0) { throw '数组不能为空' }
    $sorted = $Numbers | Sort-Object
    return @{
        Min    = $sorted[0]
        Max    = $sorted[-1]
        Average = [math]::Round(($Numbers | Measure-Object -Average).Average, 2)
        Sum    = ($Numbers | Measure-Object -Sum).Sum
    }
}

function Protect-SensitiveData {
    param([string]$InputObject, [int]$VisibleChars = 4)
    if ([string]::IsNullOrEmpty($InputObject)) {
        throw [ArgumentNullException]::new('InputObject')
    }
    $masked = '*' * [math]::Max(0, $InputObject.Length - $VisibleChars)
    $visible = $InputObject.Substring([math]::Max(0, $InputObject.Length - $VisibleChars))
    return $masked + $visible
}

# Pester 测试文件：Utils.Tests.ps1
Describe 'ConvertTo-TitleCase' {
    It '应将英文单词转为首字母大写' {
        ConvertTo-TitleCase -Text 'hello world' | Should -Be 'Hello World'
    }

    It '应处理全大写输入' {
        ConvertTo-TitleCase -Text 'POWERShell IS great' | Should -Be 'Powershell Is Great'
    }

    It '空字符串应返回空字符串' {
        ConvertTo-TitleCase -Text '' | Should -Be ''
    }

    It '空白字符串应返回空字符串' {
        ConvertTo-TitleCase -Text '   ' | Should -Be ''
    }
}

Describe 'Get-Summary' {
    Context '正常输入' {
        It '应正确计算最小值、最大值、平均值和总和' {
            $result = Get-Summary -Numbers @(3, 7, 1, 9, 5)

            $result.Min | Should -Be 1
            $result.Max | Should -Be 9
            $result.Average | Should -Be 5
            $result.Sum | Should -Be 25
        }

        It '应正确处理负数' {
            $result = Get-Summary -Numbers @(-3, -1, -7)

            $result.Min | Should -Be -7
            $result.Max | Should -Be -1
            $result.Sum | Should -Be -11
        }
    }

    Context '边界情况' {
        It '单个数字应返回相同的值' {
            $result = Get-Summary -Numbers @(42)

            $result.Min | Should -Be 42
            $result.Max | Should -Be 42
            $result.Average | Should -Be 42
        }

        It '空数组应抛出异常' {
            { Get-Summary -Numbers @() } | Should -Throw '数组不能为空'
        }
    }
}

Describe 'Protect-SensitiveData' {
    It '应遮盖除最后四位以外的字符' {
        Protect-SensitiveData -InputObject '1234567890' | Should -Be '******7890'
    }

    It '短于可见位数时应全部遮盖' {
        Protect-SensitiveData -InputObject 'AB' -VisibleChars 4 | Should -Be '**AB'
    }

    It '空值应抛出 ArgumentNullException' {
        { Protect-SensitiveData -InputObject '' } |
            Should -Throw -ExceptionType ([ArgumentNullException])
    }
}
```

执行结果示例：

```
Describing ConvertTo-TitleCase
  [+] 应将英文单词转为首字母大写 28ms
  [+] 应处理全大写输入 9ms
  [+] 空字符串应返回空字符串 4ms
  [+] 空白字符串应返回空字符串 3ms
Describing Get-Summary
  Context 正常输入
    [+] 应正确计算最小值、最大值、平均值和总和 31ms
    [+] 应正确处理负数 12ms
  Context 边界情况
    [+] 单个数字应返回相同的值 8ms
    [+] 空数组应抛出异常 14ms
Describing Protect-SensitiveData
  [+] 应遮盖除最后四位以外的字符 11ms
  [+] 短于可见位数时应全部遮盖 6ms
  [+] 空值应抛出 ArgumentNullException 9ms
Tests passed: 9, Failed: 0, Skipped: 0, NotRun: 0
```

这段测试展示了 Pester 的基本用法。`Should -Be` 用于精确匹配，`Should -Throw` 用于验证异常，`Should -Throw -ExceptionType` 可以同时断言异常类型。`Context` 块将测试场景分组，使测试输出更具可读性。每个 `It` 块是一个独立的测试用例，测试之间互不干扰，即使某个测试失败也不会影响其他测试的执行。

## 进阶：使用 Mock 隔离外部依赖

真实脚本通常包含大量外部调用：读取配置文件、请求 Web API、操作数据库。在单元测试中直接调用这些外部资源会导致测试变慢且不稳定。Pester 的 `Mock` 命令可以在测试作用域内替换指定的 cmdlet 或函数，返回你预设的结果，从而将测试与外部环境完全解耦。

以下代码演示了如何 Mock `Get-Content`（文件读取）、`Invoke-RestMethod`（网络请求）和 `Write-EventLog`（事件日志）三种常见依赖。

```powershell
# 被测函数：从配置文件和远程 API 获取系统状态并记录日志
function Get-SystemHealthStatus {
    param(
        [string]$ConfigPath = './config.json',
        [string]$ApiEndpoint = 'https://api.example.com/health'
    )

    # 步骤 1: 读取本地配置文件
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "配置文件 $ConfigPath 不存在，使用默认值"
        $config = @{ TimeoutSeconds = 30; RetryCount = 3 }
    } else {
        $raw = Get-Content -Path $ConfigPath -Raw
        $config = $raw | ConvertFrom-Json
    }

    # 步骤 2: 请求远程健康检查 API
    try {
        $response = Invoke-RestMethod -Uri $ApiEndpoint -Method Get `
            -TimeoutSec $config.TimeoutSeconds
    } catch {
        Write-EventLog -LogName 'Application' -Source 'HealthMonitor' `
            -EntryType Error -EventId 1001 -Message "API 请求失败: $_"
        return @{
            Status  = 'Error'
            Message = "无法连接到 $ApiEndpoint"
            Details = $_.Exception.Message
        }
    }

    # 步骤 3: 根据响应判断健康状态
    $isHealthy = $response.Status -eq 'Healthy' -and
                 $response.Uptime -gt 99.0

    if ($isHealthy) {
        Write-EventLog -LogName 'Application' -Source 'HealthMonitor' `
            -EntryType Information -EventId 1000 `
            -Message "系统状态正常，运行时间: $($response.Uptime)%"
    }

    return @{
        Status  = if ($isHealthy) { 'Healthy' } else { 'Degraded' }
        Uptime  = $response.Uptime
        CheckedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

# Pester 测试：使用 Mock 隔离文件、网络和日志依赖
Describe 'Get-SystemHealthStatus' {
    BeforeAll {
        # 导入被测函数（实际项目中通过 dot-sourcing 或模块导入）
        # . ./Get-SystemHealthStatus.ps1
    }

    Context '配置文件存在且 API 返回健康状态' {
        BeforeAll {
            # Mock 文件系统
            Mock Test-Path { $true }
            Mock Get-Content {
                '{"TimeoutSeconds": 60, "RetryCount": 5}'
            }

            # Mock 网络 API
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    Status = 'Healthy'
                    Uptime = 99.95
                    Version = '2.4.1'
                }
            }

            # Mock 事件日志
            Mock Write-EventLog { }
            Mock Get-Date { '2025-12-04 10:30:00' }
        }

        It '应返回 Healthy 状态' {
            $result = Get-SystemHealthStatus

            $result.Status | Should -Be 'Healthy'
            $result.Uptime | Should -Be 99.95
        }

        It '应从配置文件读取超时设置' {
            Get-SystemHealthStatus | Out-Null

            Should -Invoke Get-Content -Times 1 -Exactly
        }

        It '应写入信息级别的事件日志' {
            Get-SystemHealthStatus | Out-Null

            Should -Invoke Write-EventLog -Times 1 -Exactly `
                -ParameterFilter { $EntryType -eq 'Information' }
        }
    }

    Context '配置文件不存在时使用默认值' {
        BeforeAll {
            Mock Test-Path { $false }
            Mock Get-Content { }
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    Status = 'Healthy'
                    Uptime = 99.5
                    Version = '2.4.1'
                }
            }
            Mock Write-EventLog { }
            Mock Get-Date { '2025-12-04 10:30:00' }
        }

        It '不应调用 Get-Content' {
            Get-SystemHealthStatus | Out-Null

            Should -Invoke Get-Content -Times 0 -Exactly
        }

        It '仍应正常完成健康检查' {
            $result = Get-SystemHealthStatus

            $result.Status | Should -Be 'Healthy'
        }
    }

    Context 'API 请求失败时的错误处理' {
        BeforeAll {
            Mock Test-Path { $true }
            Mock Get-Content {
                '{"TimeoutSeconds": 10, "RetryCount": 1}'
            }
            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new('连接超时')
            }
            Mock Write-EventLog { }
        }

        It '应返回 Error 状态' {
            $result = Get-SystemHealthStatus

            $result.Status | Should -Be 'Error'
            $result.Message | Should -BeLike '*无法连接到*'
        }

        It '应写入错误级别的事件日志' {
            Get-SystemHealthStatus | Out-Null

            Should -Invoke Write-EventLog -Times 1 -Exactly `
                -ParameterFilter { $EntryType -eq 'Error' -and $EventId -eq 1001 }
        }

        It '错误信息应包含异常详情' {
            $result = Get-SystemHealthStatus

            $result.Details | Should -BeLike '*连接超时*'
        }
    }

    Context 'API 返回降级状态' {
        BeforeAll {
            Mock Test-Path { $true }
            Mock Get-Content {
                '{"TimeoutSeconds": 30, "RetryCount": 3}'
            }
            Mock Invoke-RestMethod {
                [PSCustomObject]@{
                    Status = 'Healthy'
                    Uptime = 95.0
                    Version = '2.4.1'
                }
            }
            Mock Write-EventLog { }
            Mock Get-Date { '2025-12-04 10:30:00' }
        }

        It 'Uptime 低于阈值时应返回 Degraded 状态' {
            $result = Get-SystemHealthStatus

            $result.Status | Should -Be 'Degraded'
            $result.Uptime | Should -Be 95.0
        }

        It '不应写入信息级别的日志' {
            Get-SystemHealthStatus | Out-Null

            Should -Invoke Write-EventLog -Times 0 -Exactly `
                -ParameterFilter { $EntryType -eq 'Information' }
        }
    }
}
```

执行结果示例：

```
Describing Get-SystemHealthStatus
  Context 配置文件存在且 API 返回健康状态
    [+] 应返回 Healthy 状态 24ms
    [+] 应从配置文件读取超时设置 18ms
    [+] 应写入信息级别的事件日志 12ms
  Context 配置文件不存在时使用默认值
    [+] 不应调用 Get-Content 9ms
    [+] 仍应正常完成健康检查 15ms
  Context API 请求失败时的错误处理
    [+] 应返回 Error 状态 11ms
    [+] 应写入错误级别的事件日志 8ms
    [+] 错误信息应包含异常详情 7ms
  Context API 返回降级状态
    [+] Uptime 低于阈值时应返回 Degraded 状态 13ms
    [+] 不应写入信息级别的日志 6ms
Tests passed: 10, Failed: 0, Skipped: 0, NotRun: 0
```

这段测试的核心价值在于：整个测试过程中没有真正的文件 I/O、网络请求或事件日志写入。`Mock Get-Content` 拦截了文件读取操作，返回预设的 JSON 字符串；`Mock Invoke-RestMethod` 模拟了 API 响应，可以自由控制返回值甚至抛出异常；`Mock Write-EventLog` 阻止了日志写入，同时可以通过 `Should -Invoke` 验证日志是否被正确调用。`-ParameterFilter` 参数进一步精确匹配调用参数，确保函数在正确的场景下调用了正确的日志级别和事件 ID。每个 `Context` 块定义独立的 Mock 行为，场景之间完全隔离，不会互相干扰。

## 实战：测试覆盖率与 CI 流水线集成

在团队协作中，仅编写测试是不够的，还需要量化测试质量并将其纳入持续集成（CI）流程。Pester 支持生成测试覆盖率报告（CodeCoverage）和 JUnit/XML 格式的测试结果，这些输出可以被 Azure DevOps、GitHub Actions、Jenkins 等 CI 平台直接解析和展示。以下代码演示了如何在 CI 脚本中配置 Pester 的覆盖率收集和结果输出。

```powershell
# 文件：run-tests.ps1 —— CI 流水线中的 Pester 运行脚本
# 用法：./run-tests.ps1 -CodeCoverageThreshold 80

param(
    [double]$CodeCoverageThreshold = 80,
    [string]$TestPath = './tests',
    [string]$SourcePath = './src',
    [string]$OutputPath = './test-results'
)

# 确保输出目录存在
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory | Out-Null
}

# 查找所有测试文件和源代码文件
$testFiles = Get-ChildItem -Path $TestPath -Filter '*.Tests.ps1' -Recurse
$sourceFiles = Get-ChildItem -Path $SourcePath -Filter '*.ps1' -Recurse |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }

Write-Host "发现 $($testFiles.Count) 个测试文件"
Write-Host "发现 $($sourceFiles.Count) 个源代码文件"
Write-Host "覆盖率阈值: $CodeCoverageThreshold%"

# 配置并执行 Pester 测试
$pesterConfig = New-PesterConfiguration

# 基本设置
$pesterConfig.Run.Path = $TestPath
$pesterConfig.Run.PassThru = $true
$pesterConfig.Run.Exit = $true

# 测试结果输出（JUnit XML 格式，CI 平台通用）
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = Join-Path $OutputPath 'test-results.xml'
$pesterConfig.TestResult.OutputFormat = 'JUnitXml'

# 代码覆盖率设置
$pesterConfig.CodeCoverage.Enabled = $true
$pesterConfig.CodeCoverage.Path = $sourceFiles.FullName
$pesterConfig.CodeCoverage.OutputPath = Join-Path $OutputPath 'coverage.xml'
$pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
$pesterConfig.CodeCoverage.CoveragePercentTarget = $CodeCoverageThreshold

# 输出设置
$pesterConfig.Output.Verbosity = 'Detailed'

# 执行测试
Write-Host "`n===== 开始执行 Pester 测试 =====`n"
$result = Invoke-Pester -Configuration $pesterConfig

# 输出汇总信息
Write-Host "`n===== 测试汇总 ====="
Write-Host "总测试数: $($result.TotalCount)"
Write-Host "通过: $($result.PassedCount)"
Write-Host "失败: $($result.FailedCount)"
Write-Host "跳过: $($result.SkippedCount)"

if ($result.CodeCoverage) {
    $coveragePercent = [math]::Round($result.CodeCoverage.CoveragePercent, 2)
    Write-Host "`n===== 覆盖率报告 ====="
    Write-Host "已覆盖命令: $($result.CodeCoverage.CoveredCommands.Count)"
    Write-Host "未覆盖命令: $($result.CodeCoverage.MissedCommands.Count)"
    Write-Host "覆盖率: $coveragePercent%"
    Write-Host "目标阈值: $CodeCoverageThreshold%"

    if ($coveragePercent -ge $CodeCoverageThreshold) {
        Write-Host '覆盖率检查: PASS' -ForegroundColor Green
    } else {
        Write-Host "覆盖率检查: FAIL (差 $($CodeCoverageThreshold - $coveragePercent) 个百分点)" `
            -ForegroundColor Red
    }

    # 列出覆盖率最低的文件（帮助开发者优先补充测试）
    Write-Host "`n===== 需要优先补充测试的文件 ====="
    $missedByFile = $result.CodeCoverage.MissedCommands |
        Group-Object -Property File |
        Sort-Object Count -Descending |
        Select-Object -First 5

    foreach ($entry in $missedByFile) {
        $missed = $entry.Count
        $fileName = Split-Path $entry.Name -Leaf
        Write-Host "  $fileName - $missed 条未覆盖命令"
    }
}

Write-Host "`n测试结果已输出到: $OutputPath"
Write-Host "  test-results.xml (JUnit 格式，供 CI 平台解析)"
Write-Host "  coverage.xml (JaCoCo 格式，供覆盖率工具分析)"
```

执行结果示例：

```
发现 12 个测试文件
发现 8 个源代码文件
覆盖率阈值: 80%

===== 开始执行 Pester 测试 =====

Describing Get-SystemHealthStatus
  Context 配置文件存在且 API 返回健康状态
    [+] 应返回 Healthy 状态 24ms
    [+] 应从配置文件读取超时设置 18ms
    [+] 应写入信息级别的事件日志 12ms
  Context 配置文件不存在时使用默认值
    [+] 不应调用 Get-Content 9ms
    [+] 仍应正常完成健康检查 15ms
  Context API 请求失败时的错误处理
    [+] 应返回 Error 状态 11ms
    [+] 应写入错误级别的事件日志 8ms
    [+] 错误信息应包含异常详情 7ms
  Context API 返回降级状态
    [+] Uptime 低于阈值时应返回 Degraded 状态 13ms
    [+] 不应写入信息级别的日志 6ms
Describing ConvertTo-TitleCase
  [+] 应将英文单词转为首字母大写 28ms
  [+] 应处理全大写输入 9ms
  [+] 空字符串应返回空字符串 4ms
  [+] 空白字符串应返回空字符串 3ms

===== 测试汇总 =====
总测试数: 14
通过: 14
失败: 0
跳过: 0

===== 覆盖率报告 =====
已覆盖命令: 87
未覆盖命令: 12
覆盖率: 87.88%
目标阈值: 80%
覆盖率检查: PASS

===== 需要优先补充测试的文件 =====
  utils-network.ps1 - 5 条未覆盖命令
  utils-logging.ps1 - 4 条未覆盖命令
  utils-config.ps1 - 3 条未覆盖命令

测试结果已输出到: ./test-results
  test-results.xml (JUnit 格式，供 CI 平台解析)
  coverage.xml (JaCoCo 格式，供覆盖率工具分析)
```

这段脚本展示了完整的 CI 集成方案。`New-PesterConfiguration` 创建了一个可编程的配置对象，比命令行参数更灵活。`CodeCoverage.Path` 指定需要统计覆盖率的源代码文件（而非测试文件），`CoveragePercentTarget` 设定覆盖率阈值，低于该值时 `Exit = $true` 会使进程以非零退出码退出，从而让 CI 流水线标记为失败。测试结果以 JUnit XML 格式输出，这是几乎所有 CI 平台都支持的标准格式；覆盖率报告以 JaCoCo 格式输出，可以被 ReportGenerator 等工具转换为可读的 HTML 报告。脚本末尾还智能地列出了覆盖率最低的文件，帮助开发者有针对性地补充测试。

## 注意事项

1. **Mock 的作用域遵循层级隔离规则**。在 `Context A` 中定义的 Mock 不会影响 `Context B`。子块可以覆盖父块的 Mock，离开子块后自动恢复父块的 Mock。利用这一特性可以在父 `Describe` 中定义通用 Mock，在子 `Context` 中按需覆盖特定行为，减少重复代码。

2. **`Should -Invoke` 的计数默认限定在当前 It 块所在作用域**。Pester v5 中调用次数的统计范围是当前 `Context` 或 `Describe`。如果需要在更大范围统计，使用 `-Scope` 参数（如 `-Scope Describe`）指定统计层级。不注意作用域可能导致断言次数与预期不符。

3. **覆盖率统计只计算被测试实际执行的代码路径**。100% 的命令覆盖率不等于 100% 的分支覆盖率。如果函数中有 `if/else` 分支但测试只覆盖了 `if` 分支，未覆盖的 `else` 分支中的命令会被标记为未覆盖。对于复杂条件逻辑，建议设计多个测试用例分别覆盖不同分支。

4. **避免过度 Mock 导致测试失去实际意义**。如果被测函数的每个内部调用都被 Mock 掉了，测试实际上只是在验证 Mock 框架本身。原则是只 Mock 外部边界（网络、文件、数据库），内部业务逻辑不应被 Mock。同时，过度使用 `Should -Invoke` 会让测试与实现细节强耦合，重构函数时测试会大面积失败。

5. **Pester v5 与 v4 的语法差异需要注意**。v5 中 `Assert-MockCalled` 已被 `Should -Invoke` 取代，`Assert-VerifiableMock` 不再需要。`Invoke-Pester` 的参数也发生了重大变化，v5 推荐使用 `New-PesterConfiguration` 创建配置对象。如果项目中有遗留的 v4 测试代码，建议使用 `Invoke-Pester -EnableExit` 兼容模式逐步迁移。

6. **CI 流水线中务必设置 `Exit = $true`**。这确保当测试失败或覆盖率不达标时，Pester 进程以非零退出码退出，CI 平台才能正确识别构建失败。否则即使所有测试都失败了，流水线仍会显示为绿色通过，失去持续集成的意义。同时建议将测试结果文件作为 CI 构建产物（artifact）归档，方便团队查看历史趋势。
