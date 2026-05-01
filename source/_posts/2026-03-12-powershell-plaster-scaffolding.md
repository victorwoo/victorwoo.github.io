---
layout: post
date: 2026-03-12 08:00:00
title: "PowerShell 技能连载 - Plaster 项目脚手架"
description: PowerTip of the Day - Plaster Project Scaffolding in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- plaster
- scaffolding
- module
- template
---

_适用于 PowerShell 5.1 及以上版本_

每次创建新的 PowerShell 模块项目，都需要手动建立目录结构、编写模块清单（`.psd1`）、创建入口脚本（`.psm1`）、添加 Pester 测试文件，甚至还要配置 CI/CD 流水线。这些重复劳动不仅耗时，而且容易出现结构不一致的问题，尤其在多人协作的团队中更为突出。

Plaster 是由 PowerShell 社区开发的正式项目脚手架工具，它的灵感来源于 Node.js 的 Yeoman 和 Python 的 Cookiecutter。Plaster 使用 XML 模板来定义完整的项目结构，通过声明式的方式描述文件、目录、参数和条件逻辑，一键生成标准化的项目骨架。

借助 Plaster，团队可以将最佳实践固化到模板中——无论是代码规范、测试框架配置，还是 Git 钩子和 CI 流水线——每次创建新项目时都能保持结构一致，大幅降低遗漏关键配置的风险。

## Plaster 模板基础

Plaster 模板的核心是一个 `plasterManifest.xml` 文件，它定义了模板的元数据、用户参数和文件生成规则。下面是一个最基础的模块模板示例。

首先安装 Plaster 模块：

```powershell
Install-Module -Name Plaster -Scope CurrentUser -Force
```

然后创建模板目录结构和清单文件：

```powershell
# 创建模板目录
$templatePath = "$HOME\PlasterTemplates\BasicModule"
New-Item -Path $templatePath -ItemType Directory -Force

# 创建 plasterManifest.xml
$manifestContent = @'
<?xml version="1.0" encoding="utf-8"?>
<plasterManifest
  schemaVersion="1.1"
  templateType="Project"
  xmlns="http://www.microsoft.com/schemas/PowerShell/Plaster/v1">

  <metadata>
    <name>BasicModuleTemplate</name>
    <id>9a4e5d6f-7b8c-4a3b-2c1d-0e9f8a7b6c5d</id>
    <version>1.0.0</version>
    <title>基础 PowerShell 模块模板</title>
    <description>生成一个标准结构的 PowerShell 模块项目</description>
    <author>DevOps Team</author>
    <tags>Module, Pester, CI</tags>
  </metadata>

  <parameters>
    <parameter name="ModuleName"
               type="text"
               prompt="请输入模块名称" />

    <parameter name="ModuleDescription"
               type="text"
               prompt="请输入模块描述" />

    <parameter name="AuthorName"
               type="text"
               prompt="请输入作者名称"
               default="$env:USERNAME" />

    <parameter name="ModuleVersion"
               type="text"
               prompt="请输入初始版本号"
               default="0.1.0" />
  </parameters>

  <content>
    <message>&#10;&#10;正在创建基础模块项目...&#10;</message>

    <!-- 创建目录结构 -->
    <file source=""
          destination="src\Functions\Public" />
    <file source=""
          destination="src\Functions\Private" />
    <file source=""
          destination="tests" />
    <file source=""
          destination="docs" />

    <!-- 生成模块入口文件 -->
    <templateFile
      source="module.psm1.t"
      destination="src\{{PLASTER_PARAM_ModuleName}}.psm1" />

    <!-- 生成模块清单 -->
    <templateFile
      source="manifest.psd1.t"
      destination="src\{{PLASTER_PARAM_ModuleName}}.psd1" />

    <!-- 生成测试文件 -->
    <templateFile
      source="test.Tests.ps1.t"
      destination="tests\{{PLASTER_PARAM_ModuleName}}.Tests.ps1" />

    <message>&#10;模块项目已成功创建！&#10;</message>
  </content>
</plasterManifest>
'@

$manifestContent | Set-Content -Path "$templatePath\plasterManifest.xml" -Encoding UTF8
```

同时需要创建模板文件。以模块入口文件模板 `module.psm1.t` 为例：

```powershell
# 创建模块入口模板
$psm1Template = @'
# {{PLASTER_PARAM_ModuleName}} 模块入口
# 由 Plaster 于 {{PLASTER_Date}} 生成

$PublicFunctions = @( Get-ChildItem -Path "$PSScriptRoot\Functions\Public\*.ps1" -ErrorAction SilentlyContinue )
$PrivateFunctions = @( Get-ChildItem -Path "$PSScriptRoot\Functions\Private\*.ps1" -ErrorAction SilentlyContinue )

foreach ($import in @($PublicFunctions + $PrivateFunctions)) {
    try {
        . $import.FullName
    } catch {
        Write-Error "无法导入函数 $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $PublicFunctions.BaseName
'@

$psm1Template | Set-Content -Path "$templatePath\module.psm1.t" -Encoding UTF8
```

调用模板创建项目：

```powershell
$destPath = "$HOME\Projects\MyNewModule"
Invoke-Plaster -TemplatePath $templatePath -DestinationPath $destPath
```

执行结果示例：

```
请输入模块名称: MyStorageToolkit
请输入模块描述: 存储管理工具集
请输入作者名称 [victorwoo]:
请输入初始版本号 [0.1.0]:

正在创建基础模块项目...

   创建目录: src\Functions\Public
   创建目录: src\Functions\Private
   创建目录: tests
   创建目录: docs
   创建文件: src\MyStorageToolkit.psm1
   创建文件: src\MyStorageToolkit.psd1
   创建文件: tests\MyStorageToolkit.Tests.ps1

模块项目已成功创建！
```

## 高级模板功能

基础模板能满足简单需求，但实际团队项目中往往需要根据用户选择来决定生成哪些内容。Plaster 支持 `choice`（单选）、`multichoice`（多选）和条件判断，让模板具备灵活的定制能力。

下面是一个带有高级功能的模板清单片段：

```powershell
# 高级模板的 parameters 和 content 部分
$advancedManifest = @'
<parameters>
  <parameter name="ModuleName"
             type="text"
             prompt="请输入模块名称" />

  <parameter name="ModuleDescription"
             type="text"
             prompt="请输入模块描述" />

  <parameter name="License"
             type="choice"
             prompt="请选择许可证类型"
             default="1"
             store="text">
    <choice label="&amp;MIT"
            help="MIT 许可证"
            value="MIT" />
    <choice label="&amp;Apache"
            help="Apache 2.0 许可证"
            value="Apache" />
    <choice label="&amp;None"
            help="不添加许可证"
            value="None" />
  </parameter>

  <parameter name="Options"
             type="multichoice"
             prompt="请选择要包含的功能（空格选择，回车确认）"
             default="0,1"
             store="text">
    <choice label="&amp;Pester 测试框架"
            help="添加 Pester 测试"
            value="Pester" />
    <choice label="&amp;GitHub Actions CI"
            help="添加 GitHub Actions 工作流"
            value="GitHubActions" />
    <choice label="&amp;VS Code 配置"
            help="添加 .vscode 目录"
            value="VSCode" />
    <choice label="&amp;帮助文档"
            help="添加帮助文档模板"
            value="HelpDocs" />
  </parameter>

  <parameter name="Editor"
             type="choice"
             prompt="请选择编辑器配置"
             default="0"
             store="text">
    <choice label="&amp;VS Code"
            help="Visual Studio Code"
            value="VSCode" />
    <choice label="&amp;其他"
            help="不生成编辑器配置"
            value="None" />
  </parameter>
</parameters>
'@

$advancedManifest | Set-Content -Path "$templatePath\advanced_params.xml" -Encoding UTF8
```

使用条件逻辑控制文件生成：

```powershell
# 条件生成的 content 片段
$contentSnippet = @'
<content>
  <!-- 条件生成：仅当选择 Pester 时创建测试 -->
  <condition condition="$PLASTER_PARAM_Options -contains 'Pester'">
    <file source="" destination="tests" />
    <templateFile source="test.Tests.ps1.t"
                  destination="tests\{{PLASTER_PARAM_ModuleName}}.Tests.ps1" />
    <message>已添加 Pester 测试框架配置</message>
  </condition>

  <!-- 条件生成：仅当选择 GitHub Actions 时创建 CI 配置 -->
  <condition condition="$PLASTER_PARAM_Options -contains 'GitHubActions'">
    <file source="" destination=".github\workflows" />
    <templateFile source="ci.yml.t"
                  destination=".github\workflows\ci.yml" />
    <message>已添加 GitHub Actions CI 配置</message>
  </condition>

  <!-- 条件生成：仅当选择 VS Code 时创建编辑器配置 -->
  <condition condition="$PLASTER_PARAM_Editor -eq 'VSCode'">
    <file source="" destination=".vscode" />
    <templateFile source="settings.json.t"
                  destination=".vscode\settings.json" />
    <templateFile source="extensions.json.t"
                  destination=".vscode\extensions.json" />
    <message>已添加 VS Code 配置</message>
  </condition>

  <!-- 条件生成：仅当选择帮助文档时创建 -->
  <condition condition="$PLASTER_PARAM_Options -contains 'HelpDocs'">
    <file source="" destination="docs" />
    <templateFile source="readme.md.t"
                  destination="docs\{{PLASTER_PARAM_ModuleName}}.md" />
    <message>已添加帮助文档模板</message>
  </condition>
</content>
'@

$contentSnippet | Set-Content -Path "$templatePath\content_snippet.xml" -Encoding UTF8
```

运行高级模板时，交互界面如下：

```
请输入模块名称: MyStorageToolkit
请输入模块描述: 存储管理工具集

请选择许可证类型
  [1] MIT
  [2] Apache
  [3] None
  选择 [1]: 1

请选择要包含的功能（空格选择，回车确认）
  [x] 1. Pester 测试框架
  [x] 2. GitHub Actions CI
  [ ] 3. VS Code 配置
  [ ] 4. 帮助文档
  选择 [0,1]:

请选择编辑器配置
  [1] VS Code
  [2] 其他
  选择 [1]: 1

   创建目录: tests
   创建文件: tests\MyStorageToolkit.Tests.ps1
   已添加 Pester 测试框架配置
   创建目录: .github\workflows
   创建文件: .github\workflows\ci.yml
   已添加 GitHub Actions CI 配置
   创建目录: .vscode
   创建文件: .vscode\settings.json
   创建文件: .vscode\extensions.json
   已添加 VS Code 配置
```

## 团队模板实战

将模板纳入团队协作流程的关键在于模板的版本管理和共享分发。下面展示一个完整的团队模块模板，并将模板打包发布到内部 PowerShell 仓库。

首先创建完整的模板项目结构：

```powershell
# 团队模板项目初始化
$teamTemplatePath = "$HOME\PlasterTemplates\TeamStandardModule"
$directories = @(
    "$teamTemplatePath\src\Functions\Public"
    "$teamTemplatePath\src\Functions\Private"
    "$teamTemplatePath\src\Classes"
    "$teamTemplatePath\tests\Unit"
    "$teamTemplatePath\tests\Integration"
    "$teamTemplatePath\examples"
    "$teamTemplatePath\docs"
    "$teamTemplatePath\.github\workflows"
    "$teamTemplatePath\.vscode"
)

foreach ($dir in $directories) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
}
```

创建 GitHub Actions CI 工作流模板文件 `ci.yml.t`：

```powershell
$ciTemplate = @'
name: CI - {{PLASTER_PARAM_ModuleName}}

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: {{PLASTER_PARAM RunnerType}}
    strategy:
      matrix:
        powershell-version: ['7.2', '7.4']

    steps:
      - uses: actions/checkout@v4

      - name: 安装 PowerShell ${{ '{{' }} matrix.powershell-version {{ '}}' }}
        uses: PowerShell/setup-pwsh@v1

      - name: 安装依赖模块
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -Scope CurrentUser
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

      - name: 执行 Pester 测试
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = './tests'
          $config.Output.Verbosity = 'Detailed'
          $config.CodeCoverage.Enabled = $true
          $config.CodeCoverage.Path = './src/*.psm1'
          Invoke-Pester -Configuration $config

      - name: 执行 Script Analyzer
        shell: pwsh
        run: |
          Invoke-ScriptAnalyzer -Path './src' -Severity Warning
'@

$ciTemplate | Set-Content -Path "$teamTemplatePath\ci.yml.t" -Encoding UTF8
```

将模板打包为 PowerShell 模块，方便团队安装：

```powershell
# 创建模板分发模块的清单
$moduleDir = "$HOME\Projects\TeamPlasterTemplates"
New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null

# 将模板文件复制到模块目录中
Copy-Item -Path $teamTemplatePath -Destination "$moduleDir\Templates" -Recurse -Force

# 创建模块入口脚本，提供快速调用函数
$moduleScript = @'
function Install-TeamModuleTemplate {
    <#
    .SYNOPSIS
    使用团队标准模板创建新的 PowerShell 模块项目
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [string]$TemplatePath = "$PSScriptRoot\Templates\TeamStandardModule"
    )

    if (-not (Get-Module -ListAvailable -Name Plaster)) {
        throw "请先安装 Plaster 模块: Install-Module -Name Plaster -Scope CurrentUser"
    }

    Invoke-Plaster -TemplatePath $TemplatePath -DestinationPath $DestinationPath
}

Export-ModuleMember -Function Install-TeamModuleTemplate
'@

$moduleScript | Set-Content -Path "$moduleDir\TeamPlasterTemplates.psm1" -Encoding UTF8

# 生成模块清单
$manifestParams = @{
    Path              = "$moduleDir\TeamPlasterTemplates.psd1"
    RootModule        = "TeamPlasterTemplates.psm1"
    ModuleVersion     = "1.0.0"
    Author            = "DevOps Team"
    Description       = "团队标准 PowerShell 模块 Plaster 模板"
    FunctionsToExport = @("Install-TeamModuleTemplate")
    RequiredModules   = @("Plaster")
    PowerShellVersion = "5.1"
}
New-ModuleManifest @manifestParams

Write-Host "团队模板模块已创建: $moduleDir" -ForegroundColor Green
```

发布到内部 NuGet 仓库或复制到团队共享路径后，团队成员即可一键使用：

```powershell
# 安装团队模板模块
Install-Module -Name TeamPlasterTemplates -Repository InternalPSGallery -Scope CurrentUser

# 使用团队模板创建新项目
Import-Module TeamPlasterTemplates
Install-TeamModuleTemplate -DestinationPath "$HOME\Projects\NewProject"
```

执行结果示例：

```
请输入模块名称: NetworkMonitor
请输入模块描述: 网络监控与分析工具集
请输入作者名称 [victorwoo]:
请输入初始版本号 [0.1.0]:

请选择许可证类型
  选择 [1]: 1 (MIT)

请选择要包含的功能（空格选择，回车确认）
  [x] 1. Pester 测试框架
  [x] 2. GitHub Actions CI
  [x] 3. VS Code 配置
  [x] 4. 帮助文档

   创建目录: src\Functions\Public
   创建目录: src\Functions\Private
   创建目录: src\Classes
   创建目录: tests\Unit
   创建目录: tests\Integration
   创建目录: examples
   创建目录: .github\workflows
   创建文件: .github\workflows\ci.yml
   创建目录: .vscode
   创建文件: .vscode\settings.json
   创建目录: docs
   创建文件: docs\NetworkMonitor.md

模块项目 NetworkMonitor 已创建完成！
目录结构:
  src/
    Functions/
      Public/
      Private/
    Classes/
    NetworkMonitor.psm1
    NetworkMonitor.psd1
  tests/
    Unit/
    Integration/
    NetworkMonitor.Tests.ps1
  examples/
  docs/
  .github/workflows/ci.yml
  .vscode/
```

## 注意事项

1. **模板清单必须使用 UTF-8 编码**。Plaster 解析 XML 时对编码敏感，如果清单文件包含中文且未使用 UTF-8 编码，会导致解析失败或乱码。保存文件时务必指定 `-Encoding UTF8`。

2. **模板变量语法为双花括号**。Plaster 使用 `{{PLASTER_PARAM_Name}}` 引用参数，`{{PLASTER_Date}}` 获取当前日期。注意这与 PowerShell 本身的 `$variable` 语法不同，不要混淆。

3. **条件表达式使用 PowerShell 语法**。`<condition>` 标签中的 `condition` 属性值会被当作 PowerShell 表达式求值，因此可以使用 `-contains`、`-eq`、`-and`、`-or` 等运算符组合复杂条件。

4. **模板文件扩展名建议使用 `.t` 后缀**。例如 `module.psm1.t`、`ci.yml.t`。这样可以让编辑器识别它们为模板而非实际脚本，避免 IDE 的语法检查报错。

5. **测试模板时使用 `-Force` 参数**。`Invoke-Plaster` 在目标目录已存在文件时会跳过覆盖。开发调试模板时加上 `-Force` 参数可以强制覆盖，方便反复测试。

6. **团队共享模板建议打包为 PowerShell 模块**。将模板文件嵌入到 `.psm1` 模块中并通过内部 NuGet 仓库分发，可以统一版本管理，避免团队成员使用过时模板。结合 `RequiredModules` 声明 Plaster 依赖，确保安装即用。
