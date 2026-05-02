---
layout: post
date: 2026-01-30 08:00:00
updated: 2026-01-30 08:00:00
title: "PowerShell 技能连载 - 静态代码分析"
description: PowerTip of the Day - Static Code Analysis in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- testing
- best-practices
---

_适用于 PowerShell 5.1 及以上版本_

编写 PowerShell 脚本时，很多人只关注"能不能跑通"，却忽略了代码的可读性、安全性和可维护性。变量命名不规范、使用了已弃用的 cmdlet、硬编码凭据等问题，在脚本量少时不容易暴露，但当团队协作或代码库膨胀到数百个脚本时，技术债务会迅速累积。

PSScriptAnalyzer 是 PowerShell 官方提供的静态代码分析工具，基于 .NET Compiler Platform 构建。它内置了数十条规则，覆盖代码风格、潜在 Bug、安全风险和性能问题等多个维度。每条规则都标注了严重级别（Error、Warning、Information），方便团队根据自身需求配置合适的检查策略。

本文将从 PSScriptAnalyzer 的基础使用入手，讲解如何开发自定义规则以满足团队编码规范，最后演示如何将它集成到 CI/CD 流水线中实现自动化的代码质量门控。

<!-- more -->

## PSScriptAnalyzer 基础：安装与规则扫描

PSScriptAnalyzer 作为 PowerShell Gallery 上的模块发布，安装和更新都很便捷。安装完成后，核心命令 `Invoke-ScriptAnalyzer` 可以对单个文件或整个目录执行规则扫描，并支持按严重级别、规则名称进行过滤。

```powershell
# 安装 PSScriptAnalyzer 模块
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# 查看所有可用的内置规则
Get-ScriptAnalyzerRule | Select-Object RuleName, Severity, Description |
    Format-Table -Wrap

# 创建一个示例脚本用于测试
$testScript = @'
# BadScript.ps1 - 包含多种典型问题
$var = Get-ChildItem
foreach ($item in $var) {
    if ($item.Length -gt 100kb) {
        echo "$($item.Name) is large"
    }
}
Write-Host "Done"
'@

$testScript | Set-Content -Path './BadScript.ps1' -Encoding UTF8

# 对示例脚本执行全面分析
$results = Invoke-ScriptAnalyzer -Path './BadScript.ps1'

# 按严重级别分组查看结果
$results | Group-Object Severity | Format-Table Name, Count

# 只显示 Warning 及以上级别的诊断信息
$results | Where-Object { $_.Severity -in 'Error', 'Warning' } |
    Select-Object Severity, Line, RuleName, Message |
    Format-Table -AutoSize

# 以详细格式输出（适合代码审查）
$results | Format-List Severity, RuleName, Line, Column, Message
```

```text
RuleName                            Severity Description
--------                            -------- -----------
PSAvoidDefaultValueForMandatoryParameter Warning ...
PSAvoidUsingWriteHost                Warning ...
PSUseShouldProcessForStateChangingFunctions Warning ...
PSUseApprovedVerbs                   Warning ...
PSUseSingularNouns                   Information ...
...

Name     Count
----     -----
Warning      3
Information  2

Severity RuleName                  Line Message
-------- --------                  ---- -------
Warning  PSAvoidUsingWriteHost        8 File 'BadScript.ps1' rule ...
Warning  PSAvoidUsingCmdletAliases    5 ...
Warning  PSUseApprovedVerbs           3 ...

Severity   : Warning
RuleName   : PSAvoidUsingWriteHost
Line       : 8
Column     : 1
Message    : File 'BadScript.ps1' rule PSAvoidUsingWriteHost was not...
```

从输出可以看到，PSScriptAnalyzer 对示例脚本检测出了多处问题：使用了 `Write-Host`（应改用 `Write-Output`）、使用了 `echo` 别名（应使用完整 cmdlet 名称 `Write-Output`）等。`Get-ScriptAnalyzerRule` 可以列出所有内置规则，在配置团队规范时非常有用。通过 `Where-Object` 过滤严重级别，可以让代码审查聚焦在高优先级问题上。

## 自定义规则：打造团队专属编码规范

内置规则覆盖了通用场景，但每个团队往往有自己的编码约定——比如函数注释必须包含作者和日期、变量名必须使用 PascalCase、禁用特定的 cmdlet 等。PSScriptAnalyzer 支持通过编写 PowerShell 类来开发自定义规则，规则可以打包为模块供团队共享。

```powershell
# --- 文件: CustomRules/AvoidGlobalVariable.psm1 ---
# 自定义规则：禁止使用全局变量

using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic

class AvoidGlobalVariable : IRule {
    [string] GetSeverity() { return 'Warning' }
    [string] GetName() { return 'AvoidGlobalVariable' }
    [string] GetCommonName() { return '避免使用全局变量' }
    [string] GetDescription() { return '全局变量会增加代码耦合度，建议使用参数传递或模块作用域变量' }
    [string] GetSourceName() { return 'MyTeamCustomRules' }
    [int] GetSourceVersion() { return 1 }

    [System.Collections.Generic.IEnumerable[DiagnosticRecord]] GetViolation(
        [System.Management.Automation.Language.Ast]$ast,
        [string]$filePath
    ) {
        $violations = [System.Collections.Generic.List[DiagnosticRecord]]::new()

        # 查找所有 VariableExpressionAst，检查是否以 $global: 开头
        $variableAsts = $ast.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)

        foreach ($varAst in $variableAsts) {
            $varName = $varAst.VariablePath.UserPath
            if ($varAst.VariablePath.IsGlobal -or $varName -match '^global:') {
                $record = [DiagnosticRecord]::new(
                    "检测到全局变量 `$$varName，建议使用参数或模块作用域变量替代",
                    $varAst.Extent,
                    $this.GetName(),
                    $this.GetSeverity(),
                    $filePath
                )
                $violations.Add($record)
            }
        }
        return $violations
    }
}

# 导出规则类
Export-ModuleMember -Function ([System.Management.Automation.Language.Ast]]::new) -Variable ''
```

上面是自定义规则的源码。接下来演示如何使用自定义规则，以及如何创建团队共享的规则集配置文件。

```powershell
# 使用自定义规则扫描脚本
$customRulePath = './CustomRules/AvoidGlobalVariable.psm1'
Invoke-ScriptAnalyzer -Path './BadScript.ps1' -CustomRulePath $customRulePath

# 创建团队规则集配置（profile 定义启用/禁用哪些规则）
$profileContent = @{
    IncludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSAvoidUsingCmdletAliases'
        'PSUseApprovedVerbs'
        'PSUseDeclaredVarsMoreThanAssignments'
        'AvoidGlobalVariable'  # 自定义规则
    )
    ExcludeRules = @(
        'PSUseSingularNouns'   # 团队允许复数名词
    )
    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
            Allowlist = @('select', 'where', 'sort', 'group')  # 允许的别名
        }
        PSAvoidUsingWriteHost = @{
            Enable = $true
        }
    }
}

$profileContent | ConvertTo-Json -Depth 5 |
    Set-Content -Path './TeamScriptAnalyzerProfile.json' -Encoding UTF8

# 使用团队规则集执行分析
Invoke-ScriptAnalyzer -Path './src/' -Recurse `
    -Profile './TeamScriptAnalyzerProfile.json' `
    -CustomRulePath './CustomRules/' |
    Select-Object Severity, RuleName, Line, Message |
    Format-Table -AutoSize

# 统计违规数量，用于 CI 质量门控
$allResults = Invoke-ScriptAnalyzer -Path './src/' -Recurse `
    -Profile './TeamScriptAnalyzerProfile.json'
$errorCount = ($allResults | Where-Object Severity -eq 'Error').Count
$warningCount = ($allResults | Where-Object Severity -eq 'Warning').Count
Write-Output "扫描完成: $errorCount 个错误, $warningCount 个警告"
```

```text
Severity RuleName               Line Message
-------- --------               ---- -------
Warning  AvoidGlobalVariable      3 检测到全局变量 $global:Config，建议使用参数或模块作用域变量替代
Warning  PSAvoidUsingWriteHost    8 ...

扫描完成: 0 个错误, 5 个警告
```

自定义规则通过实现 `IRule` 接口的 PowerShell 类来编写，核心逻辑在 `GetViolation` 方法中遍历 AST 节点进行匹配。规则集配置文件（Profile）以 JSON 格式定义，可以精确控制启用哪些规则、禁用哪些规则以及规则参数。这种方式让团队能够将编码规范版本化管理，新成员只需引用同一份 Profile 即可保持代码风格一致。

## CI/CD 集成：自动化代码质量门控

将 PSScriptAnalyzer 集成到 CI/CD 流水线中，可以在代码合并前自动拦截质量问题。以下示例分别展示 GitHub Actions 和 Azure DevOps 的配置方式，并实现基于违规计数的质量门控。

```powershell
# --- 文件: scripts/Invoke-QualityGate.ps1 ---
# CI/CD 质量门控脚本，供流水线调用

param(
    [string]$SourcePath = './src/',
    [string]$ProfilePath = './TeamScriptAnalyzerProfile.json',
    [string]$CustomRulesPath = './CustomRules/',
    [int]$MaxErrors = 0,
    [int]$MaxWarnings = 10
)

# 执行分析
$splat = @{
    Path     = $SourcePath
    Recurse  = $true
    Severity = @('Error', 'Warning')
}

if (Test-Path $ProfilePath) {
    $splat['Profile'] = $ProfilePath
}
if (Test-Path $CustomRulesPath) {
    $splat['CustomRulePath'] = $CustomRulesPath
}

$results = Invoke-ScriptAnalyzer @splat

# 统计并报告
$errorCount = ($results | Where-Object Severity -eq 'Error').Count
$warningCount = ($results | Where-Object Severity -eq 'Warning').Count

Write-Output "=== PSScriptAnalyzer 质量门控报告 ==="
Write-Output "扫描路径: $SourcePath"
Write-Output "错误数量: $errorCount (阈值: $MaxErrors)"
Write-Output "警告数量: $warningCount (阈值: $MaxWarnings)"
Write-Output ""

if ($results) {
    $results | Select-Object Severity, RuleName, @{N='File';E={
        Split-Path $_.ScriptPath -Leaf}}, Line, Message |
        Format-Table -AutoSize
}

# 质量门控判断
$gatePassed = $true
if ($errorCount -gt $MaxErrors) {
    Write-Output "质量门控失败: 错误数 $errorCount 超过阈值 $MaxErrors"
    $gatePassed = $false
}
if ($warningCount -gt $MaxWarnings) {
    Write-Output "质量门控失败: 警告数 $warningCount 超过阈值 $MaxWarnings"
    $gatePassed = $false
}

if ($gatePassed) {
    Write-Output "质量门控通过"
    exit 0
} else {
    Write-Output "质量门控未通过"
    exit 1
}
```

接下来是 GitHub Actions 的工作流配置。

```yaml
# --- 文件: .github/workflows/powershell-lint.yml ---
name: PowerShell Script Analysis

on:
  push:
    paths:
      - '**.ps1'
      - '**.psm1'
  pull_request:
    paths:
      - '**.ps1'
      - '**.psm1'

jobs:
  analyze:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: 安装 PSScriptAnalyzer
        shell: pwsh
        run: Install-Module PSScriptAnalyzer -Force -Scope CurrentUser

      - name: 执行代码质量分析
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path './src/' -Recurse `
            -Profile './TeamScriptAnalyzerProfile.json' `
            -Severity Error, Warning

          # 输出 GitHub Actions 注解（在 PR 中直接显示问题位置）
          foreach ($r in $results) {
            $level = $r.Severity.ToString().ToLower()
            $file = $r.ScriptPath
            $line = $r.Line
            Write-Output "::$level file=$file,line=$line::$($r.RuleName): $($r.Message)"
          }

          # 质量门控
          $errors = ($results | Where-Object Severity -eq 'Error').Count
          if ($errors -gt 0) {
            Write-Output "发现 $errors 个错误，阻止合并"
            exit 1
          }

      - name: 上传分析报告
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: analysis-report
          path: ./analysis-report.json
```

```text
=== PSScriptAnalyzer 质量门控报告 ===
扫描路径: ./src/
错误数量: 0 (阈值: 0)
警告数量: 3 (阈值: 10)

Severity RuleName                  File            Line Message
-------- --------                  ---            ---- -------
Warning  PSAvoidUsingWriteHost     Deploy.ps1       15 File 'Deploy.ps1' ...
Warning  PSAvoidUsingCmdletAliases Utils.ps1        22 ...
Warning  AvoidGlobalVariable       Config.ps1        5 检测到全局变量 ...

质量门控通过
```

CI/CD 集成的核心思路是：用 `Invoke-QualityGate.ps1` 统一封装分析逻辑和质量门控判断，流水线只需调用该脚本并根据退出码决定是否继续。GitHub Actions 配置中使用了 `::error` 和 `::warning` 注解语法，分析结果会直接显示在 PR 的 Files Changed 标签页中，审查者无需切换工具即可定位问题。Azure DevOps 也有类似的 Logging Command 机制（`##vso[task.logissue]`），原理相通。

## 注意事项

1. **规则配置应渐进式引入**：不要一次性启用所有规则并设为 Error 级别，这会让存量代码库瞬间产生大量失败。建议先以 Warning 级别启用核心规则，逐步修复存量问题后再提高门控标准。

2. **自定义规则需要充分测试**：自定义规则基于 AST 解析实现，边界情况较多（如字符串内含变量名、嵌套作用域等）。建议为每条自定义规则编写单元测试，使用 `Invoke-ScriptAnalyzer` 验证误报和漏报率。

3. **性能考量**：PSScriptAnalyzer 对大文件或大量文件的分析可能较慢。在 CI 中可以只扫描变更文件（结合 `git diff` 获取文件列表），或设置超时阈值，避免分析环节阻塞流水线。

4. **规则集版本化管理**：团队规则集配置文件（Profile）应纳入 Git 仓库管理，与代码一同进行版本控制。规则变更应通过 PR 审查，确保团队成员达成共识。

5. **与编辑器集成提升体验**：VS Code 的 PowerShell 扩展内置了 PSScriptAnalyzer 支持，可以在编写代码时实时显示问题标记。开发者在本地修复大部分问题后再提交，减少 CI 反复失败的次数。

6. **注意 PowerShell 版本差异**：部分规则的行为在不同 PowerShell 版本中可能不同。例如 `PSUseShouldProcessForStateChangingFunctions` 规则的判断逻辑在 PowerShell 7 中有所增强。建议 CI 环境使用与生产环境一致的 PowerShell 版本执行分析。
