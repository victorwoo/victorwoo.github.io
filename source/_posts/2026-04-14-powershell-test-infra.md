---
layout: post
date: 2026-04-14 08:00:00
updated: 2026-04-14 08:00:00
title: "PowerShell 技能连载 - 基础设施测试"
description: PowerTip of the Day - Infrastructure Testing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- testing
- infrastructure
- pester
- devops
---

_适用于 PowerShell 7.0 及以上版本，需要 Pester v5+ 模块_

随着基础设施即代码（IaC）的广泛采用，越来越多的团队使用 PowerShell DSC、Ansible、Terraform 等工具来定义和管理服务器配置。然而，写好了配置代码并不等于部署一定正确——就像应用代码需要单元测试一样，基础设施代码同样需要一套系统化的测试策略来保证部署结果与预期一致。

基础设施测试与传统软件测试有所不同：它验证的不是函数的输入输出，而是操作系统服务是否运行、端口是否监听、文件权限是否合规、注册表键值是否正确。这类测试通常在部署完成后执行，作为 CI/CD 流水线的最后防线，一旦发现异常就阻断发布或触发回滚。

Pester 是 PowerShell 生态中最强大的测试框架，其描述式语法（Describe / Context / It）天然适合编写基础设施验证用例。本文将从 Pester 基础设施测试框架的搭建、合规性测试套件的编写、到部署验证管道的集成，完整展示如何用 PowerShell 构建一套可靠的基础设施测试体系。

<!-- more -->

## Pester 基础设施测试框架

第一个场景是搭建基础设施测试的基本框架。我们用 Pester 编写针对服务器配置的测试用例，验证关键资源（服务、端口、文件、注册表）是否存在且处于期望状态。测试用例可以参数化，方便在不同环境（dev / staging / prod）中复用。

下面的脚本定义了一套基础设施测试，通过外部 JSON 配置文件描述期望状态，Pester 负责逐项断言：

```powershell
function Invoke-InfrastructureTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ExpectedStatePath,

        [ValidateSet('Minimal', 'Standard', 'Comprehensive')]
        [string]$TestDepth = 'Standard',

        [string]$OutputPath = 'TestResults.xml'
    )

    $stateConfig = Get-Content -Path $ExpectedStatePath -Raw | ConvertFrom-Json

    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Detailed'

    if ($OutputPath) {
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = $OutputPath
        $pesterConfig.TestResult.OutputFormat = 'JUnitXml'
    }

    $container = New-PesterContainer -ScriptBlock {
        param($Config, $Depth)

        Describe "基础设施状态验证 - $($Config.environmentName)" {
            BeforeAll {
                $testStartTime = Get-Date
                Write-Host "  测试开始时间: $testStartTime" -ForegroundColor DarkGray
            }

            # 验证 Windows 服务状态
            Context "Windows 服务检查" {
                foreach ($svc in $Config.services) {
                    It "服务 '$($svc.name)' 应处于 $($svc.expectedStatus) 状态" {
                        $service = Get-Service -Name $svc.name -ErrorAction SilentlyContinue
                        $service | Should -Not -BeNullOrEmpty -Because "服务 '$($svc.name)' 必须存在"
                        $service.Status.ToString() | Should -Be $svc.expectedStatus
                    }
                }
            }

            # 验证网络端口监听
            Context "网络端口检查" {
                foreach ($port in $Config.ports) {
                    It "端口 $($port.number)/$($port.protocol) 应处于监听状态" {
                        $protocol = if ($port.protocol -eq 'UDP') { 'Udp' } else { 'Tcp' }
                        $listener = Get-NetTCPConnection -LocalPort $port.number `
                            -ErrorAction SilentlyContinue |
                            Where-Object { $_.State -eq 'Listen' }

                        $listener | Should -Not -BeNullOrEmpty `
                            -Because "端口 $($port.number) 必须有进程监听"
                    }
                }
            }

            # 验证文件和目录
            Context "文件系统检查" {
                foreach ($file in $Config.files) {
                    if ($file.type -eq 'Directory') {
                        It "目录 '$($file.path)' 应该存在" {
                            Test-Path -Path $file.path -PathType Container |
                                Should -BeTrue -Because "目录 '$($file.path)' 必须存在"
                        }
                    }
                    else {
                        It "文件 '$($file.path)' 应该存在且内容包含 '$($file.expectedContent)'" {
                            Test-Path -Path $file.path -PathType Leaf |
                                Should -BeTrue -Because "文件 '$($file.path)' 必须存在"

                            if ($file.expectedContent) {
                                $content = Get-Content -Path $file.path -Raw
                                $content | Should -Match $file.expectedContent
                            }
                        }
                    }
                }
            }

            # 深度测试：注册表和权限（仅 Standard 和 Comprehensive 级别）
            if ($Depth -in @('Standard', 'Comprehensive')) {
                Context "注册表键值检查" {
                    foreach ($reg in $Config.registryKeys) {
                        It "注册表 '$($reg.path)\$($reg.name)' 应为 '$($reg.expectedValue)'" {
                            $actual = Get-ItemProperty -Path $reg.path -Name $reg.name `
                                -ErrorAction SilentlyContinue
                            $actual.$($reg.name) | Should -Be $reg.expectedValue
                        }
                    }
                }
            }

            AfterAll {
                $duration = (Get-Date) - $testStartTime
                Write-Host "  测试耗时: $($duration.ToString('mm\:ss\.fff'))" -ForegroundColor DarkGray
            }
        }
    } -Data @{ Config = $stateConfig; Depth = $TestDepth }

    $pesterConfig.Run.Container = $container
    $result = Invoke-Pester -Configuration $pesterConfig

    return $result
}
```

执行结果示例：

```
PS> Invoke-InfrastructureTest -ExpectedStatePath .\expected-state.json -TestDepth Standard

Starting discovery in 1 files.
Discovery finished in 0.23s.
[+] D:\infra-tests\expected-state.json 1.82s (7.3ms|1.81s)
  [+] 基础设施状态验证 - production
    [+] Windows 服务检查
      [+] 服务 'W3SVC' 应处于 Running 状态
      [+] 服务 'MSSQLSERVER' 应处于 Running 状态
    [+] 网络端口检查
      [+] 端口 443/TCP 应处于监听状态
      [+] 端口 1433/TCP 应处于监听状态
    [+] 文件系统检查
      [+] 文件 'D:\app\appsettings.json' 应该存在且内容包含 'Production'
    [+] 注册表键值检查
      [+] 注册表 'HKLM:\SOFTWARE\MyApp\Server' 应为 '10.0.1.50'
Tests passed: 6, Failed: 0, Skipped: 0, NotRun: 0
TestResults.xml written to TestResults.xml
```

## 合规性测试套件

第二个场景是构建一套完整的合规性测试套件，用于安全基线检查和 CIS Benchmark 验证。与基础的状态检查不同，合规性测试更关注安全策略的落地情况，如密码策略、审计日志、防火墙规则、用户权限等，并支持环境间差异检测。

下面的脚本定义了一套可扩展的合规性测试框架，支持按分类执行，输出详细的合规报告：

```powershell
function Invoke-ComplianceTestSuite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaselinePath,

        [string[]]$Categories = @('AccountPolicy', 'AuditPolicy', 'Firewall', 'UserRights'),

        [string]$EnvironmentName = 'default',

        [string]$ReportPath = 'ComplianceReport.json'
    )

    $baseline = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
    $complianceResults = [System.Collections.Generic.List[PSObject]]::new()
    $totalPassed = 0
    $totalFailed = 0

    foreach ($category in $Categories) {
        Write-Host "`n--- 检查分类: $category ---" -ForegroundColor Cyan

        $checks = $baseline.$category
        if (-not $checks) {
            Write-Host "  跳过（基线中无 '$category' 配置）" -ForegroundColor DarkGray
            continue
        }

        foreach ($check in $checks) {
            $testResult = $null
            $actualValue = $null

            try {
                switch ($category) {
                    'AccountPolicy' {
                        $netAccounts = net accounts |
                            Out-String | ForEach-Object {
                                if ($_ -match "$($check.key)\s*:\s*(.+)") { $Matches[1].Trim() }
                            }
                        $actualValue = $netAccounts
                        $testResult = ($actualValue -eq $check.expectedValue)
                    }

                    'AuditPolicy' {
                        $auditLine = auditpol /get /subcategory:"$($check.subcategory)" |
                            Select-String -Pattern $check.subcategory
                        if ($auditLine -match 'Success') {
                            $actualValue = 'Enabled'
                        }
                        else {
                            $actualValue = 'Disabled'
                        }
                        $testResult = ($actualValue -eq $check.expectedValue)
                    }

                    'Firewall' {
                        $rule = Get-NetFirewallRule -DisplayName $check.ruleName `
                            -ErrorAction SilentlyContinue
                        if ($check.property -eq 'Enabled') {
                            $actualValue = if ($rule.Enabled -eq $true) { 'True' } else { 'False' }
                        }
                        elseif ($check.property -eq 'Direction') {
                            $actualValue = $rule.Direction.ToString()
                        }
                        $testResult = ($actualValue -eq $check.expectedValue)
                    }

                    'UserRights' {
                        $tempFile = [System.IO.Path]::GetTempFileName()
                        secedit /export /cfg $tempFile /quiet | Out-Null
                        $secContent = Get-Content -Path $tempFile -Raw
                        Remove-Item -Path $tempFile -Force

                        if ($secContent -match "$($check.privilege)\s*=\s*(.+)") {
                            $actualValue = $Matches[1].Trim()
                        }
                        $testResult = ($actualValue -eq $check.expectedValue)
                    }
                }
            }
            catch {
                $actualValue = "Error: $($_.Exception.Message)"
                $testResult = $false
            }

            $result = [PSCustomObject]@{
                Category     = $category
                CheckId      = $check.id
                Description  = $check.description
                Expected     = $check.expectedValue
                Actual       = $actualValue
                Passed       = [bool]$testResult
                Severity     = $check.severity
                Environment  = $EnvironmentName
                Timestamp    = Get-Date -Format 'o'
            }

            $complianceResults.Add($result)

            if ($testResult) {
                $totalPassed++
                Write-Host "  [通过] [$($check.id)] $($check.description)" -ForegroundColor Green
            }
            else {
                $totalFailed++
                $color = if ($check.severity -eq 'Critical') { 'Red' } else { 'Yellow' }
                Write-Host "  [失败] [$($check.id)] $($check.description)" -ForegroundColor $color
                Write-Host "         期望: $($check.expectedValue)  实际: $actualValue" -ForegroundColor DarkGray
            }
        }
    }

    # 输出摘要
    $total = $totalPassed + $totalFailed
    $passRate = if ($total -gt 0) { [math]::Round(($totalPassed / $total) * 100, 1) } else { 0 }

    Write-Host "`n========== 合规性摘要 ==========" -ForegroundColor Cyan
    Write-Host "  环境: $EnvironmentName"
    Write-Host "  总检查项: $total"
    Write-Host "  通过: $totalPassed  失败: $totalFailed"
    Write-Host "  合规率: $passRate%"
    Write-Host "================================"

    # 写入报告文件
    $report = [PSCustomObject]@{
        Environment   = $EnvironmentName
        GeneratedAt   = Get-Date -Format 'o'
        TotalChecks   = $total
        Passed        = $totalPassed
        Failed        = $totalFailed
        PassRate      = $passRate
        Results       = $complianceResults
    }
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $ReportPath
    Write-Host "报告已保存至: $ReportPath" -ForegroundColor DarkGray

    return $report
}
```

执行结果示例：

```
PS> Invoke-ComplianceTestSuite -BaselinePath .\cis-baseline.json -EnvironmentName prod -ReportPath .\prod-compliance.json

--- 检查分类: AccountPolicy ---
  [通过] [ACC-001] 密码最短长度应为 14 个字符
  [失败] [ACC-002] 密码最长使用期限应为 90 天
         期望: 90  实际: 180
--- 检查分类: AuditPolicy ---
  [通过] [AUD-001] 登录审核应启用
  [通过] [AUD-002] 对象访问审核应启用
--- 检查分类: Firewall ---
  [通过] [FW-001] 防火墙域配置文件应启用
  [失败] [FW-002] RDP 入站规则应禁用
         期望: False  实际: True
--- 检查分类: UserRights ---
  [通过] [USR-001] 本地管理员组仅包含授权账户

========== 合规性摘要 ==========
  环境: prod
  总检查项: 7
  通过: 5  失败: 2
  合规率: 71.4%
================================
报告已保存至: .\prod-compliance.json
```

## 部署验证管道

第三个场景是将基础设施测试集成到部署管道中，实现部署后自动运行验证、基于测试结果判断是否回滚、以及生成可读的测试报告。这是将测试从"手动执行"升级为"自动化防线"的关键一步。

下面的脚本封装了完整的部署验证流程，支持自定义通过阈值、回滚触发、以及 HTML 报告生成：

```powershell
function Invoke-DeploymentValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TestPath,

        [double]$PassThreshold = 100.0,

        [string]$RollbackScriptPath,

        [string]$ReportOutputDir = 'ValidationReports',

        [string]$DeploymentId = "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    )

    $null = New-Item -ItemType Directory -Path $ReportOutputDir -Force
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "`n========== 部署验证管道 ==========" -ForegroundColor Cyan
    Write-Host "  部署ID: $DeploymentId"
    Write-Host "  测试路径: $TestPath"
    Write-Host "  通过阈值: $PassThreshold%"
    Write-Host "  启动时间: $timestamp"
    Write-Host "====================================`n"

    # 执行 Pester 测试
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Normal'

    $junitPath = Join-Path $ReportOutputDir "$DeploymentId-junit.xml"
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = $junitPath
    $pesterConfig.TestResult.OutputFormat = 'JUnitXml'

    $result = Invoke-Pester -Configuration $pesterConfig

    # 计算通过率
    $totalTests = $result.TotalCount
    $passedTests = $result.PassedCount
    $failedTests = $result.FailedCount
    $passRate = if ($totalTests -gt 0) {
        [math]::Round(($passedTests / $totalTests) * 100, 2)
    }
    else {
        0
    }

    Write-Host "`n--- 测试结果 ---" -ForegroundColor Cyan
    Write-Host "  总计: $totalTests  通过: $passedTests  失败: $failedTests"
    Write-Host "  通过率: $passRate%  (阈值: $PassThreshold%)"

    $passed = $passRate -ge $PassThreshold

    # 生成 HTML 报告
    $htmlPath = Join-Path $ReportOutputDir "$DeploymentId-report.html"
    $failedDetails = $result.Tests |
        Where-Object { $_.Result -eq 'Failed' } |
        ForEach-Object {
            "<li>$($_.Name) <br/><pre>$($_.ErrorRecord)</pre></li>"
        }

    $statusColor = if ($passed) { '#28a745' } else { '#dc3545' }
    $statusText = if ($passed) { 'PASSED' } else { 'FAILED' }

    $html = @"
<!DOCTYPE html>
<html>
<head><title>部署验证报告 - $DeploymentId</title></head>
<body style='font-family:Segoe UI,sans-serif;margin:40px'>
<h1 style='color:$statusColor'>部署验证: $statusText</h1>
<p>部署ID: $DeploymentId | 时间: $timestamp</p>
<p>总计: $totalTests | 通过: $passedTests | 失败: $failedTests | 通过率: $passRate%</p>
<h3>失败用例:</h3>
<ul>$($failedDetails -join "`n")</ul>
</body></html>
"@
    $html | Set-Content -Path $htmlPath -Encoding UTF8
    Write-Host "  HTML 报告: $htmlPath" -ForegroundColor DarkGray

    # 回滚判断
    if (-not $passed) {
        Write-Host "`n[失败] 通过率 $passRate% 低于阈值 $PassThreshold%" -ForegroundColor Red

        if ($RollbackScriptPath -and (Test-Path $RollbackScriptPath)) {
            Write-Host "[回滚] 正在执行回滚脚本: $RollbackScriptPath" -ForegroundColor Yellow
            try {
                & $RollbackScriptPath
                Write-Host "[回滚] 回滚完成。" -ForegroundColor Yellow
            }
            catch {
                Write-Host "[回滚失败] $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "[警告] 未指定回滚脚本，请手动处理。" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "`n[通过] 部署验证通过，所有测试均在阈值范围内。" -ForegroundColor Green
    }

    return [PSCustomObject]@{
        DeploymentId   = $DeploymentId
        Passed         = $passed
        TotalTests     = $totalTests
        PassedTests    = $passedTests
        FailedTests    = $failedTests
        PassRate       = $passRate
        HtmlReportPath = $htmlPath
        JUnitReportPath = $junitPath
    }
}
```

执行结果示例：

```
PS> Invoke-DeploymentValidation -TestPath .\infra-tests\ -PassThreshold 90 -RollbackScriptPath .\rollback.ps1 -DeploymentId deploy-20260414

========== 部署验证管道 ==========
  部署ID: deploy-20260414
  测试路径: D:\infra-tests\
  通过阈值: 90%
  启动时间: 2026-04-14 11:00:00
====================================

Discovery finished in 0.45s.
[+] D:\infra-tests\service.tests.ps1 2.31s (12 tests passed)
[+] D:\infra-tests\firewall.tests.ps1 1.08s (8 tests passed)
[-] D:\infra-tests\registry.tests.ps1 0.92s (19 passed, 1 failed)

--- 测试结果 ---
  总计: 40  通过: 39  失败: 1
  通过率: 97.5%  (阈值: 90%)
  HTML 报告: ValidationReports\deploy-20260414-report.html

[通过] 部署验证通过，所有测试均在阈值范围内。

DeploymentId    : deploy-20260414
Passed          : True
TotalTests      : 40
PassedTests     : 39
FailedTests     : 1
PassRate        : 97.5
HtmlReportPath  : ValidationReports\deploy-20260414-report.html
JUnitReportPath : ValidationReports\deploy-20260414-junit.xml
```

## 注意事项

1. **Pester 版本兼容性**：本文使用 Pester v5 的 `New-PesterConfiguration` 和 `New-PesterContainer` API，与 v3/v4 语法不兼容。可通过 `Get-Module Pester -ListAvailable` 检查已安装版本，如需升级使用 `Install-Module Pester -Force -SkipPublisherCheck`。

2. **测试用例参数化**：基础设施测试最大的挑战是环境差异。建议将所有环境特定的值（服务器名、端口、路径）抽取到外部 JSON 配置文件中，测试脚本本身只包含断言逻辑，这样同一套测试可以在不同环境中复用。

3. **合规性基线维护**：CIS Benchmark 和安全基线会随版本更新，基线 JSON 文件应纳入 Git 版本控制。每次基线更新后，先用 `-ReportOnly` 模式在非生产环境试运行，确认新规则的误报率可接受后再应用到生产环境。

4. **部署验证的幂等性**：验证管道可能因网络抖动等原因产生偶发失败。建议对关键测试加入重试逻辑（`Set-ItResult -Pending` 后重试一次），同时在设置 `PassThreshold` 时留出合理余量（如 95% 而非 100%），避免单次偶发失败阻断整个发布。

5. **回滚脚本的可靠性**：回滚脚本本身也需要测试和验证。建议将回滚脚本纳入版本控制，并在 staging 环境中定期演练。回滚操作应有详细的日志记录，包括回滚前后的状态快照，便于事后审计。

6. **测试报告的持久化**：部署验证生成的 JUnit XML 和 HTML 报告应上传到 CI/CD 平台的制品库（如 Azure Pipelines 的 Publish Test Results 任务），保留至少 90 天。长期积累的测试数据可以帮助识别反复失败的测试用例，从而优化测试套件的稳定性。
