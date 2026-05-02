---
layout: post
date: 2026-02-09 08:00:00
updated: 2026-02-09 08:00:00
title: "PowerShell 技能连载 - AST 抽象语法树解析"
description: PowerTip of the Day - AST Abstract Syntax Tree Parsing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ast
- parser
- code-analysis
- advanced
---

_适用于 PowerShell 7.0 及以上版本_

在编写和维护大量 PowerShell 脚本时，你是否想过如何程序化地"理解"一段代码的结构？正则表达式只能处理文本层面的匹配，却无法识别变量的作用域、函数的调用关系或参数的传递方式。PowerShell 内置的 AST（Abstract Syntax Tree，抽象语法树）引擎正是为此而生——它将脚本源码解析为一棵结构化的对象树，每个节点都代表一个语法元素。

AST 是 PSScriptAnalyzer、PowerShell Editor Services（VS Code 的 PowerShell 扩展底层）等工具的核心技术。掌握了 AST，你就能编写自己的代码静态分析工具、自动化重构脚本，甚至构建自定义的代码质量检查规则，在 CI/CD 流水线中实现脚本质量门禁。

本文将从 AST 的基础解析入手，逐步展示代码分析实战，最后实现一个自动重构工具，帮助你把 AST 技术应用到日常开发和运维中。

## AST 基础解析

PowerShell 提供了 `[System.Management.Automation.Language.Parser]` 类来将脚本文本解析为 AST。解析后的对象可以通过 `.Find()`、`.FindAll()` 等方法遍历，轻松提取函数定义、变量引用、命令调用等语法元素。

```powershell
# 定义一段示例脚本代码
$scriptCode = @'
function Get-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [int]$Timeout = 30
    )
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    $cpu = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $ComputerName

    $result = [PSCustomObject]@{
        Computer = $ComputerName
        OS       = $os.Caption
        CPU      = $cpu.Name
        DiskFree = ($disk | Measure-Object -Property FreeSpace -Sum).Sum
    }
    return $result
}

$computer = "SERVER01"
$info = Get-SystemInfo -ComputerName $computer
Write-Output $info
'@

# 使用 Parser 类解析脚本
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $scriptCode,
    [ref]$tokens,
    [ref]$errors
)

# 检查解析是否有错误
if ($errors.Count -gt 0) {
    Write-Host "解析错误:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  行 $($_.Extent.StartLineNumber): $($_.Message)" }
} else {
    Write-Host "脚本解析成功，AST 类型: $($ast.GetType().Name)" -ForegroundColor Green
}

# 提取所有函数定义
$functions = $ast.FindAll(
    { param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] },
    $true
)

Write-Host "`n=== 函数定义 ==="
foreach ($fn in $functions) {
    Write-Host "函数名: $($fn.Name)"
    Write-Host "  参数: $($fn.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath } )"
    Write-Host "  起始行: $($fn.Extent.StartLineNumber)"
    Write-Host "  结束行: $($fn.Extent.EndLineNumber)"
}

# 提取所有变量引用
$variables = $ast.FindAll(
    { param($node) $node -is [System.Management.Automation.Language.VariableExpressionAst] },
    $true
)

Write-Host "`n=== 变量列表（去重）==="
$uniqueVars = $variables | ForEach-Object { $_.VariablePath.UserPath } | Sort-Object -Unique
foreach ($v in $uniqueVars) {
    $count = ($variables | Where-Object { $_.VariablePath.UserPath -eq $v }).Count
    Write-Host "  `$$v (引用 $count 次)"
}

# 提取所有命令调用
$commands = $ast.FindAll(
    { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
    $true
)

Write-Host "`n=== 命令调用 ==="
$uniqueCmds = $commands | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ } | Sort-Object -Unique
foreach ($cmd in $uniqueCmds) {
    Write-Host "  $cmd"
}
```

执行结果示例：

```
脚本解析成功，AST 类型: ScriptBlockAst

=== 函数定义 ===
函数名: Get-SystemInfo
  参数: ComputerName Timeout
  起始行: 1
  结束行: 17

=== 变量列表（去重）===
  $ComputerName (引用 4 次)
  $Timeout (引用 1 次)
  $computer (引用 1 次)
  $cpu (引用 2 次)
  $disk (引用 2 次)
  $env:COMPUTERNAME (引用 1 次)
  $info (引用 1 次)
  $os (引用 2 次)
  $result (引用 2 次)

=== 命令调用 ===
  Get-CimInstance
  Get-SystemInfo
  Measure-Object
  Write-Output
```

## 代码分析实战

掌握了 AST 基础操作后，我们来实现几个实用的代码分析功能：提取脚本的依赖关系、检测未使用的变量、以及分析函数复杂度。这些功能可以帮助你在代码审查时快速发现问题。

```powershell
# 封装一个通用的 AST 分析函数
function Invoke-CodeAnalysis {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # 读取并解析脚本
    $source = Get-Content -Path $ScriptPath -Raw -Encoding Utf8
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $source, [ref]$tokens, [ref]$errors
    )

    $analysis = [ordered]@{}

    # 1. 提取外部依赖（Import-Module、using module、#require）
    $usingStatements = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.UsingStatementAst] },
        $true
    )
    $importCommands = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.CommandAst] -and
          $n.GetCommandName() -in 'Import-Module', 'Require-Module' },
        $true
    )

    $dependencies = @()
    foreach ($u in $usingStatements) {
        $dependencies += "using: $($u.Name.Value ?? $u.ModuleName)"
    }
    foreach ($ic in $importCommands) {
        $firstArg = $ic.CommandElements[1]
        if ($firstArg) {
            $dependencies += "module: $($firstArg.Value ?? $firstArg.Extent.Text)"
        }
    }
    $analysis['Dependencies'] = $dependencies

    # 2. 检测未使用的变量
    $allVarRefs = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] },
        $true
    )

    # 找出赋值语句左侧的变量（定义）
    $assignments = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] },
        $true
    )
    $assignedVars = @{}
    foreach ($a in $assignments) {
        if ($a.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
            $varName = $a.Left.VariablePath.UserPath
            $assignedVars[$varName] = $a.Left.Extent.StartLineNumber
        }
    }

    # 对比定义和引用，找出仅赋值但未读取的变量
    $unusedVars = @()
    foreach ($varName in $assignedVars.Keys) {
        $refCount = ($allVarRefs | Where-Object {
            $_.VariablePath.UserPath -eq $varName
        }).Count
        # 赋值本身算一次引用，如果只有1次则说明未使用
        if ($refCount -le 1 -and $varName -notin '_', 'null', 'true', 'false') {
            $unusedVars += [PSCustomObject]@{
                Variable = "`$$varName"
                Line     = $assignedVars[$varName]
            }
        }
    }
    $analysis['UnusedVariables'] = $unusedVars

    # 3. 函数复杂度分析（循环和条件分支数量）
    $functions = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    )

    $funcMetrics = foreach ($fn in $functions) {
        $loops = $fn.Body.FindAll(
            { param($n) $n -is [System.Management.Automation.Language.LoopStatementAst] },
            $true
        )
        $conditions = $fn.Body.FindAll(
            { param($n) $n -is [System.Management.Automation.Language.IfStatementAst] },
            $true
        )
        $pipelines = $fn.Body.FindAll(
            { param($n) $n -is [System.Management.Automation.Language.PipelineAst] },
            $true
        )
        $cmdCount = ($fn.Body.FindAll(
            { param($n) $n -is [System.Management.Automation.Language.CommandAst] },
            $true
        )).Count

        # 计算行数
        $lineCount = $fn.Extent.EndLineNumber - $fn.Extent.StartLineNumber + 1

        # 简单复杂度评分
        $complexity = $loops.Count * 2 + $conditions.Count + [math]::Floor($cmdCount / 5)
        $level = switch ($complexity) {
            { $_ -le 3 }  { "低" }
            { $_ -le 8 }  { "中" }
            { $_ -le 15 } { "高" }
            default       { "极高" }
        }

        [PSCustomObject]@{
            Function    = $fn.Name
            Lines       = $lineCount
            Loops       = $loops.Count
            Conditions  = $conditions.Count
            Commands    = $cmdCount
            Complexity  = "$complexity ($level)"
        }
    }
    $analysis['FunctionMetrics'] = $funcMetrics

    return [PSCustomObject]$analysis
}

# 分析示例脚本
$testScript = Join-Path $env:TEMP "sample-analysis.ps1"
@'
function Get-DiskReport {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    $report = foreach ($disk in $disks) {
        $freePercent = [math]::Round($disk.FreeSpace / $disk.Size * 100, 1)
        if ($freePercent -lt 10) {
            $status = "Critical"
        } elseif ($freePercent -lt 25) {
            $status = "Warning"
        } else {
            $status = "OK"
        }
        [PSCustomObject]@{
            Drive   = $disk.DeviceID
            FreePct = $freePercent
            Status  = $status
        }
    }
    return $report
}

$unusedVar = "这个变量只赋值不使用"
$result = Get-DiskReport
$result | Format-Table
'@ | Set-Content -Path $testScript -Encoding Utf8

$report = Invoke-CodeAnalysis -ScriptPath $testScript

Write-Host "=== 依赖关系 ===" -ForegroundColor Cyan
$report.Dependencies | ForEach-Object { Write-Host "  $_" }
if ($report.Dependencies.Count -eq 0) {
    Write-Host "  (无外部依赖)"
}

Write-Host "`n=== 未使用的变量 ===" -ForegroundColor Cyan
$report.UnusedVariables | Format-Table -AutoSize

Write-Host "`n=== 函数复杂度 ===" -ForegroundColor Cyan
$report.FunctionMetrics | Format-Table -AutoSize

Remove-Item -Path $testScript -Force
```

执行结果示例：

```
=== 依赖关系 ===
  (无外部依赖)

=== 未使用的变量 ===
Variable    Line
--------    ----
$unusedVar  20

=== 函数复杂度 ===

Function       Lines Loops Conditions Commands Complexity
--------       ----- ----- ---------- -------- ----------
Get-DiskReport    17     1          2        2 4 (中)
```

## 自动重构工具

AST 不仅能用来分析代码，还可以用来生成和修改代码。下面实现一个实用的重构工具：批量重命名变量、提取代码片段为独立函数，以及从函数定义自动生成帮助文档。

```powershell
# 基于 AST 的自动重构工具
function Invoke-CodeRefactor {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter(Mandatory)]
        [ValidateSet('RenameVariable', 'GenerateHelp', 'ExtractMetrics')]
        [string]$Operation,

        [string]$OldName,
        [string]$NewName
    )

    $source = Get-Content -Path $ScriptPath -Raw -Encoding Utf8
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $source, [ref]$tokens, [ref]$errors
    )

    switch ($Operation) {
        'RenameVariable' {
            if (-not $OldName -or -not $NewName) {
                throw "RenameVariable 操作需要指定 OldName 和 NewName"
            }
            # 找到所有匹配的变量 token
            $varTokens = $tokens | Where-Object {
                $_.Kind -eq 'Variable' -and
                $_.Text -match "^\$$([regex]::Escape($OldName))$"
            }

            if ($varTokens.Count -eq 0) {
                Write-Host "未找到变量 `$$OldName" -ForegroundColor Yellow
                return
            }

            # 从后往前替换，避免偏移量错乱
            $sb = [System.Text.StringBuilder]::new($source)
            $replaced = 0
            foreach ($vt in ($varTokens | Sort-Object { $_.Extent.StartOffset } -Descending)) {
                $sb.Remove($vt.Extent.StartOffset, $vt.Extent.EndOffset - $vt.Extent.StartOffset) | Out-Null
                $sb.Insert($vt.Extent.StartOffset, "`$$NewName") | Out-Null
                $replaced++
            }

            $newSource = $sb.ToString()
            $backupPath = "$ScriptPath.bak"
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force
            $newSource | Set-Content -Path $ScriptPath -Encoding Utf8 -NoNewline

            Write-Host "已将 `$$OldName 重命名为 `$$NewName (共 $replaced 处)" -ForegroundColor Green
            Write-Host "备份文件: $backupPath"
        }

        'GenerateHelp' {
            # 提取所有函数，自动生成基于 AST 的帮助文档
            $functions = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $true
            )

            foreach ($fn in $functions) {
                $helpBuilder = [System.Text.StringBuilder]::new()
                $null = $helpBuilder.AppendLine("<#")
                $null = $helpBuilder.AppendLine(".SYNOPSIS")
                $null = $helpBuilder.AppendLine("    $($fn.Name) 函数")
                $null = $helpBuilder.AppendLine("")
                $null = $helpBuilder.AppendLine(".DESCRIPTION")
                $null = $helpBuilder.AppendLine("    自动生成的帮助文档（基于 AST 解析）")
                $null = $helpBuilder.AppendLine("")

                if ($fn.Parameters) {
                    $null = $helpBuilder.AppendLine(".PARAMETERS")
                    foreach ($param in $fn.Parameters) {
                        $paramName = $param.Name.VariablePath.UserPath
                        $paramType = if ($param.Attributes.TypeName) {
                            $param.Attributes.TypeName.Name
                        } else {
                            "object"
                        }
                        $defaultValue = if ($param.DefaultValue) {
                            $param.DefaultValue.Extent.Text
                        } else {
                            "(必需)"
                        }
                        $null = $helpBuilder.AppendLine("    -$paramName [$paramType] 默认值: $defaultValue")
                    }
                    $null = $helpBuilder.AppendLine("")
                }

                # 统计函数体中的命令
                $bodyCmds = $fn.Body.FindAll(
                    { param($n) $n -is [System.Management.Automation.Language.CommandAst] },
                    $true
                ) | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ }

                $null = $helpBuilder.AppendLine(".NOTES")
                $null = $helpBuilder.AppendLine("    函数行数: $($fn.Extent.EndLineNumber - $fn.Extent.StartLineNumber + 1)")
                $null = $helpBuilder.AppendLine("    调用命令: $($bodyCmds -join ', ')")
                $null = $helpBuilder.AppendLine("#>")

                Write-Host "=== $($fn.Name) 的帮助文档 ===" -ForegroundColor Cyan
                Write-Host $helpBuilder.ToString()
            }
        }

        'ExtractMetrics' {
            # 提取脚本的整体度量信息
            $totalLines = ($source -split "`n").Count
            $codeLines = ($source -split "`n" | Where-Object {
                $_.Trim() -and $_.Trim() -notmatch '^\s*#' -and $_.Trim() -notmatch '^\s*<#' -and $_.Trim() -notmatch '^\s*#>'
            }).Count
            $commentLines = $totalLines - $codeLines

            $functions = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
                $true
            )
            $allCommands = $ast.FindAll(
                { param($n) $n -is [System.Management.Automation.Language.CommandAst] },
                $true
            )
            $uniqueCommands = $allCommands | ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ } | Sort-Object -Unique

            $metrics = [PSCustomObject]@{
                FilePath       = $ScriptPath
                TotalLines     = $totalLines
                CodeLines      = $codeLines
                CommentLines   = $commentLines
                Functions      = $functions.Count
                CommandCount   = $allCommands.Count
                UniqueCommands = $uniqueCommands.Count
                CommandList    = $uniqueCommands -join ", "
                ParseErrors    = $errors.Count
            }

            Write-Host "=== 脚本度量 ===" -ForegroundColor Cyan
            $metrics | Format-List
        }
    }
}

# 创建测试脚本并演示重构功能
$demoScript = Join-Path $env:TEMP "refactor-demo.ps1"
@'
function Get-ServiceStatus {
    param(
        [string[]]$ComputerName = @("localhost"),
        [string]$ServiceName = "WinRM"
    )
    foreach ($comp in $ComputerName) {
        $svc = Get-Service -Name $ServiceName -ComputerName $comp -ErrorAction SilentlyContinue
        if ($svc) {
            $output = [PSCustomObject]@{
                Computer = $comp
                Service  = $ServiceName
                Status   = $svc.Status
            }
            Write-Output $output
        }
    }
}

$computers = @("SERVER01", "SERVER02", "SERVER03")
Get-ServiceStatus -ComputerName $computers -ServiceName "Spooler"
'@ | Set-Content -Path $demoScript -Encoding Utf8

Write-Host "--- 演示: 变量重命名 ---" -ForegroundColor Yellow
Invoke-CodeRefactor -ScriptPath $demoScript -Operation RenameVariable -OldName "computers" -NewName "serverList"

Write-Host "`n--- 演示: 生成帮助文档 ---" -ForegroundColor Yellow
Invoke-CodeRefactor -ScriptPath $demoScript -Operation GenerateHelp

Write-Host "`n--- 演示: 提取度量信息 ---" -ForegroundColor Yellow
Invoke-CodeRefactor -ScriptPath $demoScript -Operation ExtractMetrics

# 清理
Remove-Item -Path $demoScript -Force
Remove-Item -Path "$demoScript.bak" -Force -ErrorAction SilentlyContinue
```

执行结果示例：

```
--- 演示: 变量重命名 ---
已将 $computers 重命名为 $serverList (共 1 处)
备份文件: /tmp/refactor-demo.ps1.bak

--- 演示: 生成帮助文档 ---
=== Get-ServiceStatus 的帮助文档 ===
<#
.SYNOPSIS
    Get-ServiceStatus 函数

.DESCRIPTION
    自动生成的帮助文档（基于 AST 解析）

.PARAMETERS
    -ComputerName [string[]] 默认值: @("localhost")
    -ServiceName [string] 默认值: "WinRM"

.NOTES
    函数行数: 15
    调用命令: Get-Service, Write-Output
#>

--- 演示: 提取度量信息 ---
=== 脚本度量 ===

FilePath       : /tmp/refactor-demo.ps1
TotalLines     : 18
CodeLines      : 17
CommentLines   : 1
Functions      : 1
CommandCount   : 3
UniqueCommands : 3
CommandList    : Get-Service, Get-ServiceStatus, Write-Output
ParseErrors    : 0
```

## 注意事项

1. **AST 是只读的**：PowerShell 的 AST 对象模型是只读的，不能直接修改 AST 节点来改变代码。要实现代码修改（如重命名变量），需要在原始源码字符串上基于 AST 提供的位置偏移量进行文本替换，然后重新写入文件。

2. **解析与执行分离**：AST 解析仅进行语法分析，不会执行任何代码。这意味着即使脚本中包含危险操作（如 `Remove-Item`），解析过程也是完全安全的。但也因此无法获取运行时信息，如变量的实际值和类型推断。

3. **Token 与 AST 的区别**：`ParseInput` 同时返回 AST 树和 Token 列表。Token 是词法分析的最小单元（标识符、运算符、字符串等），而 AST 是语法层面的结构化表示。做变量重命名等精确文本替换时应使用 Token 的偏移量，做结构分析时应使用 AST 节点。

4. **嵌套脚本的解析**：对于通过 `dot-sourcing`（`. .\script.ps1`）或 `Invoke-Expression` 动态加载的脚本，AST 无法自动追踪。如果需要分析完整的依赖链，必须递归解析所有引用的脚本文件。

5. **性能考虑**：对于超大脚本文件（数千行），`FindAll()` 使用递归遍历可能会产生大量对象。建议在 `$predicate` 回调中尽可能精确地过滤节点类型，避免不必要的全树遍历。如果只需要顶层元素，可以将第二个参数（`searchNestedScriptBlocks`）设为 `$false`。

6. **与 PSScriptAnalyzer 配合**：本文演示了如何从零编写 AST 分析逻辑。在实际项目中，建议优先使用 PSScriptAnalyzer 的自定义规则框架，它封装了 AST 遍历的细节，提供了标准化的规则接口和输出格式，与 VS Code 扩展和 CI/CD 流水线的集成也更加方便。
