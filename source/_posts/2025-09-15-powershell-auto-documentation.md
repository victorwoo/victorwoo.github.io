---
layout: post
date: 2025-09-15 08:00:00
updated: 2025-09-15 08:00:00
title: "PowerShell 技能连载 - 自动化文档生成"
description: "PowerTip of the Day - Automated Documentation Generation in PowerShell"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- documentation
- markdown
- auto-generation
---

_适用于 PowerShell 5.1 及以上版本_

在团队协作中，文档编写往往是最容易被忽略的一环。代码写完了，注释却迟迟没有补上；模块发布了，帮助文档还停留在初始版本。手动维护文档不仅耗时，而且容易与实际代码脱节。当 API 发生变更时，文档如果没有同步更新，就会误导使用者，甚至引发线上故障。

PowerShell 提供了丰富的元数据机制——从基于注释的帮助（Comment-Based Help）到 `[CmdletBinding()]` 属性中的参数定义，这些信息都可以被程序化地提取出来。结合 Markdown 模板引擎，我们完全可以用脚本自动生成格式统一、内容准确的文档，让代码与文档始终保持一致。

本文将介绍三种实用的自动化文档生成方案：基于注释帮助的函数文档提取、基于 AST 的代码结构分析，以及基于 JSON Schema 的配置文档自动生成。每种方案都附带可直接运行的示例代码和输出效果。

<!-- more -->

## 方案一：提取基于注释的帮助生成 Markdown

PowerShell 函数中的注释帮助块包含了 `.SYNOPSIS`、`.DESCRIPTION`、`.PARAMETER` 等结构化信息。我们可以用 `Get-Help` cmdlet 提取这些信息，再按照模板拼装成 Markdown 文档。

以下函数接收一个 PowerShell 脚本文件路径，解析其中所有函数的注释帮助，并输出格式化的 Markdown 文档：

```powershell
function Export-FunctionDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$OutputPath = ".\docs\functions.md"
    )

    $content = Get-Content -Path $Path -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $content, [ref]$null, [ref]$null
    )

    $functions = $ast.FindAll(
        { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    )

    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine("# 函数参考文档`n")
    $null = $sb.AppendLine("> 自动生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n")

    foreach ($func in $functions) {
        $funcName = $func.Name
        $null = $sb.AppendLine("## $funcName`n")

        $help = Get-Help -Name $funcName -ErrorAction SilentlyContinue

        if ($help.Synopsis) {
            $null = $sb.AppendLine("### 概述`n")
            $null = $sb.AppendLine("$($help.Synopsis)`n")
        }

        if ($help.Parameters) {
            $null = $sb.AppendLine("### 参数`n")
            $null = $sb.AppendLine("| 参数名 | 类型 | 说明 |")
            $null = $sb.AppendLine("|--------|------|------|")

            foreach ($p in $help.Parameters.Parameter) {
                $pName = $p.Name
                $pType = if ($p.type.name) { $p.type.name } else { "object" }
                $pDesc = if ($p.Description.Text) {
                    $p.Description.Text -replace "`n", " "
                } else {
                    "-"
                }
                $null = $sb.AppendLine("| $pName | $pType | $pDesc |")
            }
            $null = $sb.AppendLine()
        }
    }

    $null = New-Item -Path (Split-Path $OutputPath) -ItemType Directory -Force
    $sb.ToString() | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "文档已生成：$OutputPath"
}
```

执行结果示例：

```
# 函数参考文档

> 自动生成时间：2025-09-15 08:30:00

## Export-FunctionDocumentation

### 概述

从 PowerShell 脚本文件中提取函数的注释帮助并生成 Markdown 文档。

### 参数

| 参数名     | 类型   | 说明                                   |
|------------|--------|----------------------------------------|
| Path       | string | 要解析的脚本文件路径                   |
| OutputPath | string | 输出 Markdown 文件的路径，默认为当前目录 |
```

## 方案二：基于 AST 分析代码结构

注释帮助的覆盖范围有限，很多脚本甚至没有写帮助文本。此时可以借助 PowerShell 的 AST（Abstract Syntax Tree）解析器，直接分析代码结构——包括函数签名、参数定义、变量赋值、调用关系等，从而生成更完整的文档。

下面这段代码演示了如何递归扫描模块目录，提取每个 `.ps1` 文件中的函数定义及其参数信息：

```powershell
function Get-CodeStructureReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    $report = @()

    $files = Get-ChildItem -Path $ModulePath -Filter "*.ps1" -Recurse

    foreach ($file in $files) {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName, [ref]$tokens, [ref]$errors
        )

        $functions = $ast.FindAll(
            { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] },
            $true
        )

        foreach ($func in $functions) {
            $entry = [ordered]@{
                File       = $file.FullName
                Function   = $func.Name
                Parameters = @()
                StartLine  = $func.Extent.StartLineNumber
                EndLine    = $func.Extent.EndLineNumber
            }

            if ($func.Body.ParamBlock) {
                foreach ($param in $func.Body.ParamBlock.Parameters) {
                    $entry.Parameters += @{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.Attributes.TypeName) {
                            $param.Attributes.TypeName.Name
                        } else {
                            "undefined"
                        }
                    }
                }
            }

            $report += [PSCustomObject]$entry
        }
    }

    return $report
}

$report = Get-CodeStructureReport -ModulePath ".\modules\MyUtils"
$report | Format-Table -AutoSize
```

执行结果示例：

```
File              Function              Parameters           StartLine EndLine
----              --------              ----------           --------- -------
.\modules\My...  Get-UserInfo          {Name, Detail}              12      45
.\modules\My...  Set-ConfigValue       {Key, Value, Force}         50      78
.\modules\My...  Export-Report         {OutputPath, Format}        83     120
```

## 方案三：从 JSON Schema 生成配置文档

现代项目大量使用 JSON 或 YAML 配置文件，而 JSON Schema 既是校验规则，也是天然的文档来源。通过解析 Schema 文件中的 `title`、`description`、`default` 等字段，可以自动生成可读性极强的配置参考文档。

以下脚本读取一个 JSON Schema 文件，遍历其属性定义，输出结构化的 Markdown 配置表：

```powershell
function Export-SchemaDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SchemaPath,

        [string]$OutputPath = ".\docs\config-reference.md"
    )

    $schema = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json

    $sb = [System.Text.StringBuilder]::new()
    $title = if ($schema.title) { $schema.title } else { "配置参考" }
    $null = $sb.AppendLine("# $title`n")

    if ($schema.description) {
        $null = $sb.AppendLine("$($schema.description)`n")
    }

    $properties = $schema.properties.PSObject.Properties

    $null = $sb.AppendLine("## 属性列表`n")
    $null = $sb.AppendLine("| 属性 | 类型 | 默认值 | 说明 |")
    $null = $sb.AppendLine("|------|------|--------|------|")

    foreach ($prop in $properties) {
        $name = $prop.Name
        $type = if ($prop.Value.type) { $prop.Value.type } else { "-" }
        $default = if ($prop.Value.'default') {
            $prop.Value.'default' | ConvertTo-Json -Compress
        } else {
            "-"
        }
        $desc = if ($prop.Value.description) {
            $prop.Value.description
        } else {
            "-"
        }
        $null = $sb.AppendLine("| $name | $type | $default | $desc |")
    }

    $sb.AppendLine() | Out-Null

    if ($schema.required) {
        $null = $sb.AppendLine("## 必填字段`n")
        foreach ($field in $schema.required) {
            $null = $sb.AppendLine("- $field")
        }
    }

    $null = New-Item -Path (Split-Path $OutputPath) -ItemType Directory -Force
    $sb.ToString() | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "配置文档已生成：$OutputPath"
}

Export-SchemaDocumentation -SchemaPath ".\schema\appsettings.schema.json"
```

执行结果示例：

```
# 应用程序配置参考

本文件定义了应用程序运行时的所有可配置参数。

## 属性列表

| 属性         | 类型    | 默认值 | 说明                       |
|--------------|---------|--------|----------------------------|
| serverPort   | integer | 8080   | 服务监听端口               |
| logLevel     | string  | info   | 日志级别                   |
| enableCache  | boolean | true   | 是否启用缓存               |
| maxRetries   | integer | 3      | 最大重试次数               |
| allowedHosts | array   | ["*"]  | 允许访问的来源主机列表     |

## 必填字段

- serverPort
- logLevel
```

## 完整的流水线：一键生成模块文档

将以上三种方案组合起来，可以构建一个完整的文档生成流水线。以下脚本对指定模块目录执行全面扫描，生成包含函数参考、代码结构概览和配置说明的综合文档：

```powershell
function Publish-ModuleDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [string]$OutputDir = ".\docs"
    )

    Write-Host "=== 开始生成模块文档 ===" -ForegroundColor Cyan

    # 步骤一：生成函数参考
    Write-Host "[1/3] 生成函数参考文档..." -ForegroundColor Yellow
    $ps1Files = Get-ChildItem -Path $ModulePath -Filter "*.ps1" -Recurse
    foreach ($file in $ps1Files) {
        $name = $file.BaseName
        Export-FunctionDocumentation -Path $file.FullName `
            -OutputPath (Join-Path $OutputDir "functions\${name}.md")
    }

    # 步骤二：生成代码结构报告
    Write-Host "[2/3] 生成代码结构报告..." -ForegroundColor Yellow
    $report = Get-CodeStructureReport -ModulePath $ModulePath
    $reportPath = Join-Path $OutputDir "structure.json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

    # 步骤三：生成配置文档
    Write-Host "[3/3] 生成配置文档..." -ForegroundColor Yellow
    $schemaFiles = Get-ChildItem -Path $ModulePath -Filter "*.schema.json" -Recurse
    foreach ($sf in $schemaFiles) {
        $schemaName = $sf.BaseName -replace '\.schema$', ''
        Export-SchemaDocumentation -SchemaPath $sf.FullName `
            -OutputPath (Join-Path $OutputDir "config\${schemaName}.md")
    }

    Write-Host "=== 文档生成完毕，输出目录：$OutputDir ===" -ForegroundColor Green
}

Publish-ModuleDocumentation -ModulePath ".\modules\MyUtils"
```

执行结果示例：

```
=== 开始生成模块文档 ===
[1/3] 生成函数参考文档...
文档已生成：.\docs\functions\Utils.md
文档已生成：.\docs\functions\Helper.md
[2/3] 生成代码结构报告...
[3/3] 生成配置文档...
配置文档已生成：.\docs\config\appsettings.md
=== 文档生成完毕，输出目录：.\docs ===
```

## 注意事项

1. **注释帮助必须完整**：方案一依赖 `Get-Help`，如果函数没有编写标准的注释帮助块，输出将缺少描述和参数说明。建议团队规范中强制要求每个公开函数包含 `.SYNOPSIS` 和 `.PARAMETER` 标签。

2. **AST 解析不等于执行**：方案二使用静态分析，不会实际运行脚本，因此无法获取运行时才能确定的值（如动态参数、条件分支结果）。它适合用于代码审查和结构梳理。

3. **JSON Schema 版本兼容性**：方案三假设 Schema 文件遵循 Draft-07 或更新版本。如果遇到旧版 Schema，部分字段（如 `$id`、`examples`）可能无法正确解析，需要做额外的版本检测和降级处理。

4. **编码问题**：生成的 Markdown 文件务必使用 UTF-8 编码（`Set-Content -Encoding UTF8`）。在 Windows PowerShell 5.1 中，默认编码是系统本地编码，可能导致中文乱码；PowerShell 7 默认 UTF-8，无需额外处理。

5. **CI/CD 集成**：将文档生成脚本放入 CI 流水线中，在每次代码提交或发布时自动运行，确保文档始终与代码同步。可以在 GitHub Actions 的 `build` 阶段调用 `Publish-ModuleDocumentation`，并在 artifact 中附带生成的文档。

6. **模板可定制**：本文示例中的 Markdown 模板是硬编码的。在生产环境中，建议将模板提取为外部文件（如 `.md.tpl`），支持团队自定义样式和格式，避免每次修改模板都要改脚本代码。
