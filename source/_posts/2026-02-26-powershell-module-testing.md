---
layout: post
date: 2026-02-26 08:00:00
updated: 2026-02-26 08:00:00
title: "PowerShell 技能连载 - 模块开发与测试"
description: PowerTip of the Day - Module Development and Testing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- module
- testing
- pester
- quality
---

_适用于 PowerShell 7.0 及以上版本_

PowerShell 模块是代码复用和分发的核心单元。将常用的函数打包为模块，不仅可以让团队成员通过 `Import-Module` 一行命令加载全部功能，还能发布到 PowerShell Gallery（PSGallery）供全球社区使用。然而模块的质量直接影响使用者的信任度——一个没有测试覆盖的模块，任何一次改动都可能引入难以察觉的回归缺陷。

现代 PowerShell 模块开发已经形成了一套成熟的工程实践：使用 Plaster 脚手架工具初始化标准项目结构，用 Pester 测试框架编写单元测试和集成测试，再通过 CI/CD 流水线实现自动化构建、测试和发布。这套流程不仅能保证模块质量，还能让你在发布新版本时充满信心。

本文将从模块项目的标准结构入手，逐步展示 Pester 测试的编写方法，最后介绍如何将模块发布到 PSGallery 并接入 CI/CD 自动化流程。

<!-- more -->

## 模块项目结构

一个规范的 PowerShell 模块项目不仅包含 `.psm1` 和 `.psd1` 文件，还应该有清晰的目录组织、构建脚本和测试目录。使用 Plaster 模板可以快速生成符合社区标准的项目骨架，避免手动创建时遗漏关键文件。

```powershell
# 安装 Plaster 脚手架工具
Install-Module -Name Plaster -Scope CurrentUser -Force

# 定义模块参数
$plasterParams = @{
    TemplatePath   = (Install-Module -Name PlasterTemplate -PassThru -Force).ModuleBase
    DestinationPath = Join-Path $HOME "Projects\MyUtils"
}

# 使用内置模板创建模块项目（这里手动创建标准结构作为演示）
$moduleRoot = Join-Path $HOME "Projects\MyUtils"
$dirs = @(
    "MyUtils\functions",
    "MyUtils\internal\functions",
    "MyUtils\tests\unit",
    "MyUtils\tests\integration",
    "MyUtils\build",
    "MyUtils\docs",
    "MyUtils\examples"
)

foreach ($dir in $dirs) {
    $fullPath = Join-Path $moduleRoot $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        Write-Host "  创建目录: $dir" -ForegroundColor Green
    }
}

# 创建模块主文件（.psm1）
$psm1Content = @'
# MyUtils.psm1 - 模块入口
# 从 functions 目录加载所有公共函数
$publicFunctions = Get-ChildItem -Path "$PSScriptRoot\functions\*.ps1" -ErrorAction SilentlyContinue
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot\internal\functions\*.ps1" -ErrorAction SilentlyContinue

# 先加载私有函数
foreach ($func in $privateFunctions) {
    . $func.FullName
}

# 加载公共函数并导出
$exportedNames = @()
foreach ($func in $publicFunctions) {
    . $func.FullName
    $exportedNames += $func.BaseName
}

Export-ModuleMember -Function $exportedNames
'@

$psm1Path = Join-Path $moduleRoot "MyUtils\MyUtils.psm1"
$psm1Content | Set-Content -Path $psm1Path -Encoding Utf8

# 创建模块清单（.psd1）
$manifestParams = @{
    Path              = (Join-Path $moduleRoot "MyUtils\MyUtils.psd1")
    RootModule        = "MyUtils.psm1"
    ModuleVersion     = "1.0.0"
    Author            = "PowerShell Developer"
    Description       = "实用工具函数集合"
    PowerShellVersion = "7.0"
    FunctionsToExport = @()
    VariablesToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
    LicenseUri        = "https://opensource.org/licenses/MIT"
    ProjectUri        = "https://github.com/example/MyUtils"
    ReleaseNotes      = "初始版本发布"
}
New-ModuleManifest @manifestParams

# 创建一个示例公共函数
$sampleFunction = @'
function Get-SystemUptime {
    <#
    .SYNOPSIS
        获取系统运行时间信息
    .DESCRIPTION
        返回系统自上次启动以来的运行时长、启动时间等详细信息
    .PARAMETER ComputerName
        目标计算机名称，默认为本地
    .EXAMPLE
        Get-SystemUptime
        获取本地系统运行时间
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    $uptime = (Get-Date) - $os.LastBootUpTime

    [PSCustomObject]@{
        ComputerName = $ComputerName
        BootTime     = $os.LastBootUpTime
        UptimeDays   = [math]::Floor($uptime.TotalDays)
        UptimeHours  = [math]::Floor($uptime.TotalHours)
        Status       = if ($uptime.TotalDays -gt 30) { "需要重启" } else { "正常" }
    }
}
'@

$funcPath = Join-Path $moduleRoot "MyUtils\functions\Get-SystemUptime.ps1"
$sampleFunction | Set-Content -Path $funcPath -Encoding Utf8

# 显示最终项目结构
Write-Host "`n=== 模块项目结构 ===" -ForegroundColor Cyan
Get-ChildItem -Path (Join-Path $moduleRoot "MyUtils") -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace((Join-Path $moduleRoot "MyUtils\"), "")
    $indent = "  " * ($relativePath.Split("\").Count - 1)
    if ($_.PSIsContainer) {
        Write-Host "$indent[DIR]  $($_.Name)" -ForegroundColor Yellow
    } else {
        Write-Host "$indent       $($_.Name) ($([math]::Round($_.Length / 1KB, 1)) KB)"
    }
}
```

执行结果示例：

```
  创建目录: MyUtils\functions
  创建目录: MyUtils\internal\functions
  创建目录: MyUtils\tests\unit
  创建目录: MyUtils\tests\integration
  创建目录: MyUtils\build
  创建目录: MyUtils\docs
  创建目录: MyUtils\examples

=== 模块项目结构 ===
[DIR]  MyUtils
       [DIR]  build
       [DIR]  docs
       [DIR]  examples
       [DIR]  functions
              Get-SystemUptime.ps1 (1.2 KB)
       [DIR]  internal
              [DIR]  functions
       [DIR]  tests
              [DIR]  integration
              [DIR]  unit
       MyUtils.psd1 (2.8 KB)
       MyUtils.psm1 (0.5 KB)
```

## Pester 测试编写

Pester 是 PowerShell 社区最流行的测试框架，支持行为驱动开发（BDD）风格的测试语法。通过编写单元测试验证函数逻辑，使用 Mock 隔离外部依赖，再用集成测试验证端到端场景，可以构建出完整的测试金字塔。

```powershell
# 安装 Pester 测试框架
Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck
Import-Module Pester

# ===== 单元测试 =====
# 为 Get-SystemUptime 编写单元测试，使用 Mock 隔离 CIM 调用
$unitTest = @'
Describe "Get-SystemUptime" {
    BeforeAll {
        # Mock Get-CimInstance，避免真实调用 WMI
        Mock Get-CimInstance {
            [PSCustomObject]@{
                LastBootUpTime = (Get-Date).AddDays(-15).AddHours(-3)
            }
        }

        # Mock Get-Date，使测试结果可预测
        Mock Get-Date { [datetime]"2026-02-26 10:00:00" }
    }

    Context "当系统正常运行时" {
        It "应返回正确的运行天数" {
            $result = Get-SystemUptime
            $result.UptimeDays | Should -Be 15
        }

        It "应返回正确的运行小时数" {
            $result = Get-SystemUptime
            $result.UptimeHours | Should -Be 363
        }

        It "状态应为'正常'" {
            $result = Get-SystemUptime
            $result.Status | Should -Be "正常"
        }

        It "应返回本地计算机名" {
            $result = Get-SystemUptime
            $result.ComputerName | Should -Be $env:COMPUTERNAME
        }
    }

    Context "当指定远程计算机时" {
        It "应将计算机名传递给 Get-CimInstance" {
            Get-SystemUptime -ComputerName "SERVER01"
            Should -Invoke Get-CimInstance -Times 1 -ParameterFilter {
                $ComputerName -eq "SERVER01"
            }
        }
    }

    Context "当系统超过30天未重启时" {
        BeforeAll {
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    LastBootUpTime = (Get-Date).AddDays(-45)
                }
            }
        }

        It "状态应为'需要重启'" {
            $result = Get-SystemUptime
            $result.Status | Should -Be "需要重启"
        }
    }
}
'@

$unitTestPath = Join-Path $moduleRoot "MyUtils\tests\unit\Get-SystemUptime.Tests.ps1"
$unitTest | Set-Content -Path $unitTestPath -Encoding Utf8

# ===== 集成测试 =====
# 验证模块加载和函数导出的端到端场景
$integrationTest = @'
Describe "MyUtils 模块集成测试" {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\MyUtils.psd1"
        Import-Module $modulePath -Force
    }

    AfterAll {
        Remove-Module MyUtils -Force -ErrorAction SilentlyContinue
    }

    Context "模块加载" {
        It "应成功加载模块" {
            Get-Module -Name MyUtils | Should -Not -BeNullOrEmpty
        }

        It "应导出 Get-SystemUptime 函数" {
            $cmds = Get-Command -Module MyUtils
            $cmds.Name | Should -Contain "Get-SystemUptime"
        }
    }

    Context "函数调用" {
        It "Get-SystemUptime 应返回正确类型" {
            $result = Get-SystemUptime
            $result | Should -BeOfType [System.Management.Automation.PSCustomObject]
        }

        It "返回对象应包含预期的属性" {
            $result = Get-SystemUptime
            $result.PSObject.Properties.Name | Should -Contain "ComputerName"
            $result.PSObject.Properties.Name | Should -Contain "BootTime"
            $result.PSObject.Properties.Name | Should -Contain "UptimeDays"
            $result.PSObject.Properties.Name | Should -Contain "Status"
        }
    }
}
'@

$intTestPath = Join-Path $moduleRoot "MyUtils\tests\integration\Module.Tests.ps1"
$integrationTest | Set-Content -Path $intTestPath -Encoding Utf8

# 运行单元测试
Write-Host "=== 运行单元测试 ===" -ForegroundColor Cyan
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $unitTestPath
$pesterConfig.Output.Verbosity = "Detailed"
$pesterResult = Invoke-Pester -Configuration $pesterConfig

# 输出测试摘要
Write-Host "`n=== 测试摘要 ===" -ForegroundColor Cyan
Write-Host "总测试数: $($pesterResult.TotalCount)"
Write-Host "通过: $($pesterResult.PassedCount)" -ForegroundColor Green
Write-Host "失败: $($pesterResult.FailedCount)" -ForegroundColor Red
Write-Host "跳过: $($pesterResult.SkippedCount)" -ForegroundColor Yellow
Write-Host "执行时间: $([math]::Round($pesterResult.Duration.TotalSeconds, 2)) 秒"
```

执行结果示例：

```
=== 运行单元测试 ===
Starting discovery in 1 files.
Discovery finished in 0.12 seconds.
Running tests from 'Get-SystemUptime.Tests.ps1'
  Describing Get-SystemUptime
    Context 当系统正常运行时
      [+] 应返回正确的运行天数 38ms
      [+] 应返回正确的运行小时数 12ms
      [+] 状态应为'正常' 8ms
      [+] 应返回本地计算机名 6ms
    Context 当指定远程计算机时
      [+] 应将计算机名传递给 Get-CimInstance 15ms
    Context 当系统超过30天未重启时
      [+] 状态应为'需要重启' 10ms
Tests passed: 6, Failed: 0, Skipped: 0, NotRun: 0

=== 测试摘要 ===
总测试数: 6
通过: 6
失败: 0
跳过: 0
执行时间: 0.34 秒
```

## 发布与维护

模块开发和测试完成后，下一步是发布到 PSGallery 供他人使用。合理的版本管理、自动化构建脚本和 CI/CD 集成，能让模块的迭代发布变得高效可靠。

```powershell
# ===== 发布到 PowerShell Gallery =====
# 1. 获取 API Key（从 https://www.powershellgallery.com 获取）
# $apiKey = Get-Secret -Name "PSGalleryApiKey" -AsPlainText

# 2. 发布前检查
$modulePath = Join-Path $moduleRoot "MyUtils"
$manifest = Test-ModuleManifest -Path (Join-Path $modulePath "MyUtils.psd1")

Write-Host "模块名称: $($manifest.Name)"
Write-Host "版本号: $($manifest.Version)"
Write-Host "作者: $($manifest.Author)"
Write-Host "描述: $($manifest.Description)"

# 运行 PSScriptAnalyzer 代码质量检查
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
$analysisResult = Invoke-ScriptAnalyzer -Path $modulePath -Severity Warning,Error

if ($analysisResult) {
    Write-Host "`n=== 代码质量问题 ===" -ForegroundColor Yellow
    $analysisResult | Format-Table RuleName, Severity, Line, Message -AutoSize
} else {
    Write-Host "`n代码质量检查通过，无警告或错误" -ForegroundColor Green
}

# 发布模块（取消注释以实际发布）
# Publish-Module -Path $modulePath -NuGetApiKey $apiKey -Repository PSGallery

# ===== 版本管理辅助函数 =====
function Update-ModuleVersionLocal {
    param(
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [Parameter(Mandatory)]
        [ValidateSet("Major", "Minor", "Patch")]
        [string]$BumpType,

        [string]$ReleaseNotes
    )

    $manifestPath = Join-Path $ModulePath "*.psd1"
    $currentManifest = Test-ModuleManifest -Path $manifestPath
    $version = $currentManifest.Version

    $newVersion = switch ($BumpType) {
        "Major" { [version]::new($version.Major + 1, 0, 0) }
        "Minor" { [version]::new($version.Major, $version.Minor + 1, 0) }
        "Patch" { [version]::new($version.Major, $version.Minor, $version.Build + 1) }
    }

    # 更新清单中的版本号
    $manifestContent = Get-Content -Path $manifestPath -Raw
    $manifestContent = $manifestContent -replace
        "ModuleVersion\s*=\s*'$version'",
        "ModuleVersion = '$newVersion'"

    if ($ReleaseNotes) {
        $manifestContent = $manifestContent -replace
            "ReleaseNotes\s*=\s*'[^']*'",
            "ReleaseNotes = '$ReleaseNotes'"
    }

    $manifestContent | Set-Content -Path $manifestPath -Encoding Utf8
    Write-Host "版本已更新: $version -> $newVersion" -ForegroundColor Green
}

# 演示版本升级
Write-Host "`n=== 版本管理演示 ===" -ForegroundColor Cyan
Update-ModuleVersionLocal -ModulePath $modulePath -BumpType Minor -ReleaseNotes "新增 Get-SystemUptime 函数"

# ===== 构建脚本 =====
$buildScript = @'
# build.ps1 - 模块构建脚本
param(
    [string]$Task = "Build",
    [version]$Version
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

switch ($Task) {
    "Test" {
        Write-Host "运行测试..." -ForegroundColor Cyan
        $config = New-PesterConfiguration
        $config.Run.Path = Join-Path $projectRoot "tests"
        $config.Output.Verbosity = "Detailed"
        $result = Invoke-Pester -Configuration $config
        if ($result.FailedCount -gt 0) {
            throw "测试失败: $($result.FailedCount) 个测试未通过"
        }
        Write-Host "所有测试通过" -ForegroundColor Green
    }

    "Build" {
        Write-Host "构建模块..." -ForegroundColor Cyan
        $outputDir = Join-Path $projectRoot "output\MyUtils"
        if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
        Copy-Item -Path (Join-Path $projectRoot "MyUtils") -Destination $outputDir -Recurse
        Write-Host "构建完成: $outputDir" -ForegroundColor Green
    }

    "Publish" {
        Write-Host "发布到 PSGallery..." -ForegroundColor Cyan
        $outputDir = Join-Path $projectRoot "output\MyUtils"
        $apiKey = Get-Secret -Name "PSGalleryApiKey" -AsPlainText
        Publish-Module -Path $outputDir -NuGetApiKey $apiKey
        Write-Host "发布完成" -ForegroundColor Green
    }

    default {
        Write-Host "可用任务: Test, Build, Publish"
    }
}
'@

$buildPath = Join-Path $moduleRoot "MyUtils\build.ps1"
$buildScript | Set-Content -Path $buildPath -Encoding Utf8

# ===== CI/CD 配置示例（GitHub Actions）=====
$githubActions = @'
name: CI/CD Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PowerShell Modules
        shell: pwsh
        run: |
          Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
          Install-Module Pester, PSScriptAnalyzer -Force
      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: Invoke-ScriptAnalyzer -Path ./MyUtils -Severity Error
      - name: Run Pester Tests
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = ./tests
          Invoke-Pester -Configuration $config

  publish:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Publish to PSGallery
        shell: pwsh
        env:
          NUGET_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}
        run: |
          Publish-Module -Path ./MyUtils -NuGetApiKey $env:NUGET_API_KEY
'@

Write-Host "`n=== CI/CD 配置文件已生成 ===" -ForegroundColor Cyan
Write-Host "GitHub Actions 工作流包含以下步骤:"
Write-Host "  1. 代码检出"
Write-Host "  2. 安装依赖模块（Pester、PSScriptAnalyzer）"
Write-Host "  3. 静态代码分析"
Write-Host "  4. 运行测试套件"
Write-Host "  5. 测试通过后自动发布到 PSGallery"
```

执行结果示例：

```
模块名称: MyUtils
版本号: 1.0.0
作者: PowerShell Developer
描述: 实用工具函数集合

代码质量检查通过，无警告或错误

=== 版本管理演示 ===
版本已更新: 1.0.0 -> 1.1.0

=== CI/CD 配置文件已生成 ===
GitHub Actions 工作流包含以下步骤:
  1. 代码检出
  2. 安装依赖模块（Pester、PSScriptAnalyzer）
  3. 静态代码分析
  4. 运行测试套件
  5. 测试通过后自动发布到 PSGallery
```

## 注意事项

1. **模块清单是门面**：`New-ModuleManifest` 生成的 `.psd1` 文件是模块的元数据入口。务必确保 `FunctionsToExport`、`CmdletsToExport` 等字段显式声明导出列表，而非使用通配符 `*`。通配符导出会让模块加载变慢，还可能意外暴露内部函数。

2. **Mock 不要过度使用**：Pester 的 Mock 功能强大但容易滥用。单元测试中 Mock 外部依赖（如网络调用、WMI 查询）是合理的，但如果 Mock 层数过多，测试本身就会变得脆弱，失去验证代码逻辑的价值。建议优先测试真实逻辑，仅在 I/O 边界使用 Mock。

3. **测试与代码同步维护**：每新增或修改一个公共函数，都应同步更新对应的测试文件。可以在 CI 流水线中加入测试覆盖率检查（Pester v5 支持代码覆盖率收集），将覆盖率阈值设为 80% 以上，防止测试与代码脱节。

4. **语义化版本号**：遵循 SemVer 规范（Major.Minor.Patch）管理模块版本。破坏性变更（如删除函数、更改参数含义）升 Major，新增功能升 Minor，Bug 修复升 Patch。避免随意修改版本号，使用者可能通过版本约束来控制升级范围。

5. **PSGallery 发布前检查清单**：发布前至少完成以下检查：`Test-ModuleManifest` 验证清单完整性、`Invoke-ScriptAnalyzer` 代码质量检查、Pester 全部测试通过、README 和帮助文档更新、CHANGELOG 记录变更。缺少任何一项都可能导致用户反馈或差评。

6. **跨平台兼容性**：如果你的模块需要在 Linux 和 macOS 上运行，测试时要注意避免使用 Windows 专有命令（如注册表操作、WMI/CIM 的部分类）。可以在 GitHub Actions 中配置多平台（`ubuntu-latest`、`windows-latest`、`macos-latest`）并行测试，确保模块的跨平台兼容性。
