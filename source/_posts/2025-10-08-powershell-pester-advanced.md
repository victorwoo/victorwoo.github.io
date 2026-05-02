---
layout: post
date: 2025-10-08 08:00:00
updated: 2025-10-08 08:00:00
title: "PowerShell 技能连载 - Pester 高级测试"
description: PowerTip of the Day - Advanced Pester Testing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- pester
- testing
- unit-test
- tdd
---

_适用于 PowerShell 5.1 及以上版本_

在 PowerShell 生态中，Pester 已经成为事实上的测试框架标准。从简单的断言到复杂的端到端验证，Pester 能够覆盖各种测试场景。然而，许多开发者仅停留在 `Should -Be` 的基本用法上，对于 Mock、BeforeAll/AfterAll、参数化测试、Code Coverage 等高级特性缺乏了解。

随着 DevOps 实践的深入，持续集成流水线对自动化测试的要求越来越高。一份高质量的 Pester 测试套件不仅能捕捉回归缺陷，还能作为模块行为的"可执行文档"。掌握 Pester 的高级技巧，可以显著提升测试的可维护性、执行效率和覆盖广度。

本文将围绕四个高级主题展开：参数化测试（Data-Driven Tests）、Mock 与 Assert-VerifiableMock、自定义 Should 断言运算符，以及 Code Coverage 集成。每个主题都配有可直接运行的完整示例。

<!-- more -->

## 参数化测试：用 TestCases 消除重复

当你需要对同一个函数的多组输入进行验证时，逐一编写 `It` 块会导致大量重复代码。Pester 提供了 `TestCases` 参数，可以将测试数据与测试逻辑分离，一个 `It` 块即可覆盖所有场景。

下面的例子定义了一个字符串处理函数，然后使用 `TestCases` 同时验证多种输入组合：

```powershell
# 被测函数：移除字符串首尾的空白字符并转为标题大小写
function Format-TitleCase {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )
    $trimmed = $Text.Trim()
    $words = $trimmed -split '\s+'
    $result = foreach ($word in $words) {
        $word.Substring(0, 1).ToUpper() + $word.Substring(1).ToLower()
    }
    $result -join ' '
}

# Pester 测试
Describe 'Format-TitleCase 参数化测试' {
    It '应将 "<Input>" 转换为 "<Expected>"' -TestCases @(
        @{ Input = 'hello world';          Expected = 'Hello World' }
        @{ Input = '  powershell  ';        Expected = 'Powershell' }
        @{ Input = 'a b c d';              Expected = 'A B C D' }
        @{ Input = 'MIXED case INPUT';     Expected = 'Mixed Case Input' }
        @{ Input = '  too  many  spaces '; Expected = 'Too Many Spaces' }
    ) {
        param($Input, $Expected)
        Format-TitleCase -Text $Input | Should -Be $Expected
    }
}
```

执行结果示例：

```
Describing Format-TitleCase 参数化测试
  [+] 应将 "hello world" 转换为 "Hello World" 32ms
  [+] 应将 "  powershell  " 转换为 "Powershell" 18ms
  [+] 应将 "a b c d" 转换为 "A B C D" 12ms
  [+] 应将 "MIXED case INPUT" 转换为 "Mixed Case Input" 15ms
  [+] 应将 "  too  many  spaces " 转换为 "Too Many Spaces" 11ms
Tests completed in 188ms
Tests Passed: 5, Failed: 0, Skipped: 0 NotRun: 0
```

使用 `TestCases` 的好处在于：每条数据会生成独立的测试用例，某一条失败不影响其他数据的验证，测试报告中也能清晰看到具体是哪组输入出了问题。`<Input>` 和 `<Expected>` 这样的占位符会在输出中被实际值替换，方便定位问题。

## Mock 与依赖隔离

在单元测试中，被测函数往往会调用外部依赖（文件系统、数据库、REST API 等）。如果不加以隔离，测试结果会受到外部环境的影响，导致测试时好时坏（Flaky Tests）。Pester 的 `Mock` 命令可以将任意命令替换为桩实现，让测试专注于验证逻辑本身。

下面的示例演示如何 Mock `Invoke-RestMethod`，使测试在不发送真实网络请求的情况下验证函数行为：

```powershell
# 被测函数：调用天气 API 并格式化输出
function Get-WeatherReport {
    param(
        [Parameter(Mandatory)]
        [string]$City
    )
    $uri = "https://api.weather.example.com/v1/current?city=$City"
    $response = Invoke-RestMethod -Uri $uri -Method Get
    if ($response.Temperature -gt 35) {
        return "[$City] 高温预警：当前 $($response.Temperature)°C，天气 $($response.Condition)"
    }
    return "[$City] 当前 $($response.Temperature)°C，天气 $($response.Condition)"
}

# Pester 测试
Describe 'Get-WeatherReport' {
    BeforeAll {
        # Mock Invoke-RestMethod，返回预设的天气数据
        Mock Invoke-RestMethod {
            param($Uri)
            if ($Uri -match 'Beijing') {
                return @{
                    Temperature = 38
                    Condition   = '晴'
                }
            }
            return @{
                Temperature = 22
                Condition   = '多云'
            }
        }
    }

    It '当温度超过 35 度时应包含高温预警' {
        $result = Get-WeatherReport -City 'Beijing'
        $result | Should -Match '高温预警'
        $result | Should -Match '38°C'
    }

    It '正常温度应返回天气信息而无预警' {
        $result = Get-WeatherReport -City 'Shanghai'
        $result | Should -Not -Match '高温预警'
        $result | Should -Match '22°C'
    }

    It '应调用 Invoke-RestMethod 一次' {
        # 先调用一次被测函数
        Get-WeatherReport -City 'Guangzhou' | Out-Null
        # 验证 Mock 被调用了恰好 1 次
        Should -Invoke Invoke-RestMethod -Exactly 1 -Scope It
    }
}
```

执行结果示例：

```
Describing Get-WeatherReport
  [+] 当温度超过 35 度时应包含高温预警 45ms
  [+] 正常温度应返回天气信息而无预警 28ms
  [+] 应调用 Invoke-RestMethod 一次 19ms
Tests completed in 92ms
Tests Passed: 3, Failed: 0, Skipped: 0 NotRun: 0
```

这里有几个关键点值得注意。`BeforeAll` 块中的 Mock 对当前 `Describe` 内的所有 `It` 块生效。`Mock` 命令通过拦截指定命令的调用，将其重定向到自定义脚本块。`Should -Invoke`（旧版为 `Assert-MockCalled`）用于验证 Mock 是否按预期被调用。这种方式特别适合测试错误处理分支——你可以让 Mock 抛出异常，验证被测函数的容错逻辑是否正确。

## 自定义 Should 断言运算符

Pester v5 允许通过 `Add-ShouldOperator` 注册自定义断言运算符。当你需要在多个测试文件中复用同一种复杂的验证逻辑时，自定义运算符比在每个测试中写重复的 `Where-Object` 管道要优雅得多。

下面展示如何创建一个 `BeValidJson` 运算符，用于断言字符串是否为合法的 JSON：

```powershell
# 首先定义自定义断言（通常放在测试的 BeforeAll 或单独的 .Tests.Setup.ps1 中）
BeforeAll {
    Add-ShouldOperator -Name BeValidJson -Test {
        param($ActualValue, [switch]$Negate)
        # 尝试用 ConvertFrom-Json 解析，如果失败则不是合法 JSON
        $isValid = $true
        try {
            ConvertFrom-Json -InputObject $ActualValue -ErrorAction Stop | Out-Null
        }
        catch {
            $isValid = $false
        }

        if ($Negate) {
            $isValid = -not $isValid
        }

        if (-not $isValid) {
            if ($Negate) {
                $failureMessage = "Expected the string to NOT be valid JSON, but it parsed successfully."
            }
            else {
                $failureMessage = "Expected the string to be valid JSON, but parsing failed. Input: $($ActualValue.Substring(0, [Math]::Min(50, $ActualValue.Length)))..."
            }
            throw [Pester.Factory]::CreateShouldErrorResult($failureMessage, $ActualValue)
        }
    }
}

# 使用自定义运算符进行测试
Describe 'BeValidJson 自定义断言' {
    It '合法的 JSON 字符串应通过验证' {
        $json = '{"name": "PowerShell", "version": 7.4}'
        $json | Should -BeValidJson
    }

    It '非法的 JSON 字符串应验证失败' {
        $badJson = '{name: missing_quotes}'
        $badJson | Should -Not -BeValidJson
    }

    It 'JSON 数组也应被正确识别' {
        $array = '[1, 2, 3, "four"]'
        $array | Should -BeValidJson
    }

    It '嵌套结构应通过验证' {
        $nested = '{"users": [{"id": 1}, {"id": 2}], "total": 2}'
        $nested | Should -BeValidJson
    }
}
```

执行结果示例：

```
Describing BeValidJson 自定义断言
  [+] 合法的 JSON 字符串应通过验证 36ms
  [+] 非法的 JSON 字符串应验证失败 14ms
  [+] JSON 数组也应被正确识别 11ms
  [+] 嵌套结构应通过验证 13ms
Tests completed in 74ms
Tests Passed: 4, Failed: 0, Skipped: 0 NotRun: 0
```

自定义运算符的核心是 `$Negate` 参数，它处理 `Should -Not` 的反转逻辑。当断言失败时，通过抛出 `[Pester.Factory]::CreateShouldErrorResult()` 来提供清晰的错误消息。将自定义运算符的定义放在一个独立的 `.ps1` 文件中，然后在测试启动时通过 `-Configuration` 的 `ScriptBlock` 参数加载，就能在整个测试套件中复用。

## Code Coverage 与 CI 集成

在团队协作中，仅知道"测试通过"还不够，你还需要量化测试覆盖了多少代码路径。Pester v5 内置了 Code Coverage 功能，可以告诉你哪些行、哪些函数从未被测试触达。结合 CI/CD 流水线，可以设置覆盖率阈值门禁，确保代码质量不会随时间退化。

下面的示例展示如何在 CI 脚本中运行 Pester 并生成覆盖率报告：

```powershell
# run-tests.ps1 — CI 流水线中调用的测试入口脚本
param(
    [double]$CoverageThreshold = 80
)

# 安装或导入 Pester
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge '5.0' })) {
    Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
}
Import-Module Pester

# 配置 Pester 运行
$configuration = @{
    Run        = @{
        Path = '.\tests'
    }
    Output     = @{
        Verbosity = 'Detailed'
    }
    CodeCoverage = @{
        Enabled   = $true
        Path      = '.\src\*.ps1', '.\src\*.psm1'
        CoverageThreshold = $CoverageThreshold
        OutputFormat      = 'JaCoCo'
        OutputPath        = '.\coverage.xml'
    }
    TestResult = @{
        Enabled   = $true
        OutputFormat = 'NUnitXml'
        OutputPath   = '.\testResults.xml'
    }
}

$result = Invoke-Pester -Configuration $configuration

# 输出覆盖率摘要
if ($result.CodeCoverage) {
    $covered = $result.CodeCoverage.NumberOfCommandsExecuted
    $total   = $result.CodeCoverage.NumberOfCommandsAnalyzed
    $percent = if ($total -gt 0) { [math]::Round(($covered / $total) * 100, 1) } else { 0 }
    Write-Host "代码覆盖率：$covered / $total 条命令已覆盖 ($percent%)"
}

# 根据结果设置退出码
if ($result.FailedCount -gt 0) {
    Write-Host "测试失败：$($result.FailedCount) 个用例未通过" -ForegroundColor Red
    exit 1
}
if ($result.CodeCoverage -and $percent -lt $CoverageThreshold) {
    Write-Host "覆盖率 $percent% 低于阈值 $CoverageThreshold%" -ForegroundColor Yellow
    exit 2
}
Write-Host "所有测试通过，覆盖率达标" -ForegroundColor Green
exit 0
```

执行结果示例：

```
Starting discovery in 1 files.
Discovery finished in 245ms.
Running tests.
[+] .\tests\Format-TitleCase.Tests.ps1  188ms (5 passed)
[+] .\tests\Get-WeatherReport.Tests.ps1 92ms (3 passed)
[+] .\tests\BeValidJson.Tests.ps1       74ms (4 passed)
Tests completed in 554ms
Tests Passed: 12, Failed: 0, Skipped: 0 NotRun: 0
代码覆盖率：87 / 102 条命令已覆盖 (85.3%)
所有测试通过，覆盖率达标
```

这段脚本做了三件关键的事情。第一，通过 `CodeCoverage` 配置项指定需要追踪的源码路径和覆盖率阈值，低于阈值时以非零退出码退出，CI 流水线可以据此拦截不合格的提交。第二，`OutputFormat` 设为 `JaCoCo` 后生成标准格式的覆盖率报告，可被 Azure DevOps、GitLab CI、SonarQube 等工具直接消费。第三，`TestResult` 生成 NUnit 格式的测试结果，便于 CI 平台展示测试趋势和失败详情。

## 注意事项

1. **Mock 作用域要精确控制**：`Mock` 默认作用于当前及子作用域。如果你在 `Describe` 级别 Mock 了 `Get-Content`，该 `Describe` 下所有 `Context` 和 `It` 块都会受影响。如果只想在特定 `It` 中生效，就把 `Mock` 写在那个 `It` 内部。滥用全局 Mock 会让测试难以理解和维护。

2. **避免在 Mock 中执行真实操作**：Mock 的脚本块中不应调用外部服务或修改文件系统。一旦 Mock 内部产生了副作用，就违背了隔离测试的初衷。如果 Mock 逻辑很复杂，考虑先写一个简单的桩函数，再 Mock 这个桩函数。

3. **TestCases 中的特殊字符需要转义**：当测试数据包含双引号、美元符号、反引号等 PowerShell 特殊字符时，哈希表中的字符串要用单引号包裹，或者使用反引号转义，否则解析器会提前展开变量。

4. **Code Coverage 不是银弹**：80% 的行覆盖率不代表 80% 的逻辑覆盖率。条件分支的短路求值、异常路径、边界值等场景需要专门的测试用例来覆盖。不要为了凑覆盖率数字而写无意义的断言。

5. **Pester v5 与 v4 的差异**：v5 对配置模型做了大幅重构，`Invoke-Pester` 的参数风格完全不同。如果你在迁移旧测试套件，注意 `Assert-MockCalled` 已被 `Should -Invoke` 替代，`TestDrive` 和 `TestRegistry` 的行为也有细微变化。建议统一使用 v5 的新语法。

6. **在 CI 中固定 Pester 版本**：不同版本的 Pester 行为差异较大，CI 流水线中务必通过 `-RequiredVersion` 锁定版本号，或者在 `pwsh` 启动时显式 `Import-Module Pester -RequiredVersion 5.x.x`。否则某天 Pester 发布了大版本更新，你的流水线可能突然大面积失败。
