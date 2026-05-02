---
layout: post
date: 2025-04-21 08:00:00
updated: 2025-04-21 08:00:00
title: "PowerShell 技能连载 - CI/CD 流水线中的 PowerShell 实践"
description: PowerTip of the Day - PowerShell in CI/CD Pipelines
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- cicd
- devops
- github-actions
- automation
---
_适用于 PowerShell 7.0 及以上版本，需要 GitHub 账号_

2025 年，CI/CD（持续集成/持续部署）已经成为软件交付的标准流程。无论是小型个人项目还是企业级微服务架构，自动化构建、测试和部署的能力都直接影响着交付效率和代码质量。GitHub Actions 作为目前最流行的 CI/CD 平台之一，原生支持 PowerShell 运行环境，这让 PowerShell 用户可以无缝融入 DevOps 工作流。

PowerShell 在 CI/CD 场景中有独特优势：强大的对象管道让数据处理变得简洁，跨平台支持（PowerShell 7+）让同一套脚本可以在 Windows、Linux 和 macOS Runner 上运行，丰富的模块生态则覆盖了从代码质量检查到部署验证的各个环节。本文将从脚本设计原则出发，逐步构建一个完整的 CI/CD 流水线方案。

<!-- more -->

## 设计原则：编写可测试的 PowerShell 脚本

CI/CD 流水线的可靠性取决于其中每一段脚本的质量。一段"能跑就行"的脚本在本地可能没问题，但放到自动化流水线中，缺乏错误处理、日志输出和结构化返回值，就会成为调试噩梦。以下是编写 CI/CD 脚本时应遵循的核心原则：

1. **单一职责**：每个函数只做一件事，方便单独测试和复用
2. **显式错误处理**：使用 `try/catch` 捕获异常，绝不吞掉错误
3. **结构化输出**：返回对象而非格式化文本，方便下游消费
4. **参数化配置**：所有路径、阈值、环境变量通过参数传入，不硬编码

下面的函数演示了这些原则的实际应用：

```powershell
function Invoke-ProjectBuild {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [string]$Configuration = "Release",

        [string]$OutputPath = "./artifacts"
    )

    $ErrorActionPreference = "Stop"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        if (-not (Test-Path $ProjectPath)) {
            throw "项目路径不存在: $ProjectPath"
        }

        # 创建输出目录
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory | Out-Null
        }

        Write-Host "[BUILD] 开始构建 $ProjectPath ($Configuration)..."

        # 模拟构建过程
        $buildResult = & dotnet publish $ProjectPath `
            --configuration $Configuration `
            --output $OutputPath 2>&1

        $sw.Stop()

        $result = [PSCustomObject]@{
            Success    = $LASTEXITCODE -eq 0
            Duration   = $sw.Elapsed
            OutputPath = $OutputPath
            Timestamp  = Get-Date
        }

        if (-not $result.Success) {
            throw "构建失败，退出码: $LASTEXITCODE"
        }

        Write-Host "[BUILD] 构建完成，耗时 $($sw.Elapsed.ToString('mm\:ss'))"
        return $result
    }
    catch {
        $sw.Stop()
        Write-Error "[BUILD] 构建异常: $($_.Exception.Message)"
        throw
    }
}
```

```text
PS> Invoke-ProjectBuild -ProjectPath "./src/MyApp.csproj"
[BUILD] 开始构建 ./src/MyApp.csproj (Release)...
[BUILD] 构建完成，耗时 00:12

Success  : True
Duration : 00:00:12.3456789
OutputPath : ./artifacts
Timestamp  : 2025/4/21 10:00:00
```

## Pester 单元测试

在 CI/CD 流水线中，自动化测试是质量保障的基石。Pester 是 PowerShell 生态中最成熟的测试框架，支持 Describe/Context/It 三层组织结构，内联 Mock 能力让外部依赖的隔离变得简单。下面的测试覆盖了构建函数的正常路径和异常路径：

```powershell
BeforeAll {
    # 加载待测函数
    . "$PSScriptRoot/../build/Invoke-ProjectBuild.ps1"
}

Describe "Invoke-ProjectBuild" {
    Context "当项目路径存在时" {
        BeforeAll {
            # 创建临时项目目录
            $testProject = Join-Path $TestDrive "TestApp.csproj"
            Set-Content -Path $testProject -Value "<Project></Project>"
        }

        It "应返回成功的构建结果" {
            $result = Invoke-ProjectBuild -ProjectPath $testProject `
                -OutputPath "$TestDrive/output"

            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -BeTrue
            $result.OutputPath | Should -Exist
        }

        It "应在结果中包含耗时信息" {
            $result = Invoke-ProjectBuild -ProjectPath $testProject `
                -OutputPath "$TestDrive/output2"

            $result.Duration | Should -BeGreaterThan ([TimeSpan]::Zero)
            $result.Timestamp | Should -BeGreaterOrEqual (Get-Date).AddMinutes(-1)
        }
    }

    Context "当项目路径不存在时" {
        It "应抛出异常" {
            {
                Invoke-ProjectBuild -ProjectPath "/nonexistent/project.csproj"
            } | Should -Throw "*项目路径不存在*"
        }
    }
}
```

```text
PS> Invoke-Pester -Path ./tests/Invoke-ProjectBuild.Tests.ps1 -Output Detailed

Starting discovery in 1 files.
Discovery finished in 0.23s.
[Des] Invoke-ProjectBuild
  [Ctx] 当项目路径存在时
    [It] 应返回成功的构建结果
    [It] 应在结果中包含耗时信息
  [Ctx] 当项目路径不存在时
    [It] 应抛出异常
Tests passed: 3, Failed: 0, Skipped: 0, NotRun: 0
Total time: 1.45s
```

## GitHub Actions Workflow 配置

有了可测试的脚本之后，接下来把它集成到 GitHub Actions 中。PowerShell 在 GitHub Actions 的 Windows 和 Ubuntu Runner 上都是预装的，无需额外安装。关键配置点：

- 使用 `pwsh` shell 确保使用 PowerShell 7（而非 Windows PowerShell 5.1）
- 通过 `matrix` 策略实现跨平台并行测试
- 使用 `actions/cache` 缓存模块依赖，加速后续运行

```yaml
name: PowerShell CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest]
        include:
          - os: ubuntu-latest
            shell: pwsh
          - os: windows-latest
            shell: pwsh

    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 缓存 PowerShell 模块
        uses: actions/cache@v4
        with:
          path: ~/.local/share/powershell/Modules
          key: ps-modules-${{ runner.os }}-${{ hashFiles('**/requirements.psd1') }}

      - name: 安装 Pester
        shell: pwsh
        run: |
          Install-Module -Name Pester -Force -Scope CurrentUser
          Import-Module Pester

      - name: 运行 Lint 检查
        shell: pwsh
        run: |
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
          $results = Invoke-ScriptAnalyzer -Path ./src -Severity Warning
          if ($results) {
            $results | Format-Table -AutoSize
            Write-Error "Lint 检查未通过"
          }

      - name: 运行 Pester 测试
        shell: pwsh
        run: |
          $config = New-PesterConfiguration
          $config.Run.Path = "./tests"
          $config.Output.Verbosity = "Detailed"
          $config.TestResult.Enabled = $true
          $config.TestResult.OutputPath = "testResults.xml"
          Invoke-Pester -Configuration $config

      - name: 上传测试结果
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results-${{ matrix.os }}
          path: testResults.xml
```

```text
# GitHub Actions 运行输出摘要
Run Lint 检查
  RuleName            Severity  ScriptName    Line Message
  ----------            --------  ----------    ---- -------
  PSUseShouldProcessForStateChangingFunctions Warning  build.ps1   12

Run 运行 Pester 测试
  [+] DscResource.Tests.ps1  1.23s
  [+] Invoke-ProjectBuild.Tests.ps1  0.87s
  Tests passed: 8, Failed: 0
```

## 部署验证脚本

CI/CD 不止于构建和测试，部署后的验证同样重要。以下函数在部署完成后自动检查服务的健康状态，支持并发检测多个端点，输出结构化的结果摘要。配合流水线中的 `continue-on-error: false`，一旦任何端点异常就会中断部署。

```powershell
function Test-DeploymentHealth {
    param(
        [Parameter(Mandatory)]
        [string[]]$Endpoints,

        [int]$TimeoutSeconds = 10,

        [int]$RetryCount = 3,

        [int]$RetryDelaySeconds = 5
    )

    $results = @()

    foreach ($endpoint in $Endpoints) {
        $attempt = 0
        $success = $false

        while ($attempt -lt $RetryCount -and -not $success) {
            $attempt++
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            try {
                $response = Invoke-WebRequest -Uri $endpoint `
                    -TimeoutSec $TimeoutSeconds `
                    -UseBasicParsing

                $sw.Stop()
                $success = $response.StatusCode -eq 200

                if ($success) {
                    $results += [PSCustomObject]@{
                        Endpoint    = $endpoint
                        Status      = "OK"
                        StatusCode  = $response.StatusCode
                        LatencyMs   = $sw.ElapsedMilliseconds
                        Attempt     = $attempt
                        Timestamp   = Get-Date
                    }
                    Write-Host "[HEALTH] $endpoint - OK ($($sw.ElapsedMilliseconds)ms)"
                }
            }
            catch {
                $sw.Stop()
                Write-Warning "[HEALTH] $endpoint - 第 $attempt 次检测失败: $($_.Exception.Message)"

                if ($attempt -lt $RetryCount) {
                    Write-Host "  等待 $RetryDelaySeconds 秒后重试..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
            }
        }

        if (-not $success) {
            $results += [PSCustomObject]@{
                Endpoint   = $endpoint
                Status     = "FAIL"
                StatusCode = "N/A"
                LatencyMs  = $sw.ElapsedMilliseconds
                Attempt    = $attempt
                Timestamp  = Get-Date
            }
        }
    }

    # 检查是否有失败的端点
    $failedCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    if ($failedCount -gt 0) {
        Write-Error "[HEALTH] $failedCount 个端点检测失败！"
    }

    return $results
}
```

```text
PS> Test-DeploymentHealth -Endpoints "https://api.example.com/health","https://app.example.com"
[HEALTH] https://api.example.com/health - OK (145ms)
WARNING: [HEALTH] https://app.example.com - 第 1 次检测失败: 连接超时
  等待 5 秒后重试...
[HEALTH] https://app.example.com - OK (230ms)

Endpoint                         Status StatusCode LatencyMs Attempt Timestamp
--------                         ------ ---------- --------- ------- ---------
https://api.example.com/health   OK     200        145       1       2025/4/21 10:05:00
https://app.example.com          OK     200        230       2       2025/4/21 10:05:06
```

## 完整流水线：从构建到部署验证

将前面的组件组合在一起，就形成了一个完整的 CI/CD 编排脚本。这个入口函数按照固定阶段顺序执行，每个阶段失败都会立即中断，确保不会在构建失败的情况下继续部署：

```powershell
function Invoke-CiCdPipeline {
    param(
        [string]$ProjectPath = "./src",
        [string]$Environment = "staging",
        [string[]]$HealthEndpoints
    )

    $ErrorActionPreference = "Stop"
    $pipelineStart = Get-Date
    $stageResults = @{}

    Write-Host "========================================"
    Write-Host " CI/CD Pipeline - $Environment"
    Write-Host " 开始时间: $pipelineStart"
    Write-Host "========================================"

    # 阶段 1: Lint
    Write-Host "`n[Stage 1/4] 代码质量检查..."
    $analysisResults = Invoke-ScriptAnalyzer -Path $ProjectPath -Severity Error
    if ($analysisResults) {
        $analysisResults | Format-Table -AutoSize
        throw "代码质量检查未通过"
    }
    $stageResults["Lint"] = "PASSED"
    Write-Host "  Lint 检查通过"

    # 阶段 2: 测试
    Write-Host "`n[Stage 2/4] 运行单元测试..."
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = "./tests"
    $pesterConfig.Output.Verbosity = "Normal"
    $testResult = Invoke-Pester -Configuration $pesterConfig -PassThru
    if ($testResult.FailedCount -gt 0) {
        throw "测试失败: $($testResult.FailedCount) 个用例未通过"
    }
    $stageResults["Test"] = "PASSED ($($testResult.PassedCount) passed)"
    Write-Host "  全部 $($testResult.PassedCount) 个测试通过"

    # 阶段 3: 构建
    Write-Host "`n[Stage 3/4] 构建项目..."
    $buildResult = Invoke-ProjectBuild -ProjectPath "$ProjectPath/App.csproj"
    $stageResults["Build"] = "PASSED ($($buildResult.Duration.ToString('mm\:ss')))"
    Write-Host "  构建完成"

    # 阶段 4: 健康检查（仅当提供了端点时）
    if ($HealthEndpoints) {
        Write-Host "`n[Stage 4/4] 部署验证..."
        $healthResults = Test-DeploymentHealth -Endpoints $HealthEndpoints
        $stageResults["HealthCheck"] = "PASSED ($($HealthEndpoints.Count) endpoints)"
        Write-Host "  所有端点健康"
    }

    # 输出汇总
    $totalDuration = (Get-Date) - $pipelineStart
    Write-Host "`n========================================"
    Write-Host " Pipeline 完成"
    Write-Host " 总耗时: $($totalDuration.ToString('mm\:ss'))"
    Write-Host "========================================"

    foreach ($stage in $stageResults.GetEnumerator()) {
        Write-Host ("  {0,-15} {1}" -f $stage.Key, $stage.Value)
    }

    return [PSCustomObject]@{
        Success  = $true
        Duration = $totalDuration
        Stages   = $stageResults
    }
}
```

```text
PS> Invoke-CiCdPipeline -Environment "staging" -HealthEndpoints "https://api.example.com/health"

========================================
 CI/CD Pipeline - staging
 开始时间: 2025/4/21 10:00:00
========================================

[Stage 1/4] 代码质量检查...
  Lint 检查通过

[Stage 2/4] 运行单元测试...
  全部 8 个测试通过

[Stage 3/4] 构建项目...
[BUILD] 开始构建 ./src/App.csproj (Release)...
[BUILD] 构建完成，耗时 00:12
  构建完成

[Stage 4/4] 部署验证...
[HEALTH] https://api.example.com/health - OK (98ms)
  所有端点健康

========================================
 Pipeline 完成
 总耗时: 00:52
========================================
  Lint            PASSED
  Test            PASSED (8 passed)
  Build           PASSED (00:12)
  HealthCheck     PASSED (1 endpoints)
```

## 小结

将 PowerShell 融入 CI/CD 流水线的关键在于：脚本要可测试（Pester 覆盖正常和异常路径）、可观测（结构化日志输出）、可组合（单一职责函数通过编排脚本串联）。GitHub Actions 原生支持 `pwsh`，使得 PowerShell 脚本可以直接作为 Workflow 步骤运行，无需额外适配。建议在本地先用 Pester 充分测试脚本逻辑，再集成到 Actions Workflow 中，这样能大幅减少调试周期。
