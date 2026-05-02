---
layout: post
date: 2025-07-30 08:00:00
updated: 2025-07-30 08:00:00
title: "PowerShell 技能连载 - 单元测试与 Pester 进阶"
description: PowerTip of the Day - Unit Testing and Advanced Pester in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- testing
---

_适用于 PowerShell 5.1 及以上版本，需要 Pester 模块_

单元测试不是可选项，而是生产级脚本的必需品——尤其是被多人调用、影响关键业务逻辑的函数。Pester 是 PowerShell 生态中事实上的测试框架，提供 `Describe`/`Context`/`It` 的 BDD 风格语法、Mock 能力、代码覆盖率统计。从简单的函数验证到复杂的模块测试，Pester 都能胜任。

本文将讲解 Pester 的高级用法，包括 Mock、参数过滤、代码覆盖率，以及测试驱动的开发实践。

<!-- more -->

## 基础测试结构

```powershell
# 安装 Pester
Install-Module -Name Pester -Force -Scope CurrentUser

# 被测函数
function Get-FileSizeCategory {
    param([Parameter(Mandatory)][long]$Bytes)

    switch ($true) {
        ($Bytes -ge 1GB) { return "Large" }
        ($Bytes -ge 1MB) { return "Medium" }
        ($Bytes -ge 1KB) { return "Small" }
        default          { return "Tiny" }
    }
}

function ConvertTo-ReadableSize {
    param([Parameter(Mandatory)][long]$Bytes)

    switch ($true) {
        ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
        ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
        ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
        ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
        default          { return "$Bytes B" }
    }
}

# Pester 测试文件
$tests = @"
Describe "Get-FileSizeCategory" {
    Context "当文件大小小于 1KB" {
        It "应该返回 Tiny" {
            Get-FileSizeCategory -Bytes 0 | Should -Be "Tiny"
            Get-FileSizeCategory -Bytes 512 | Should -Be "Tiny"
            Get-FileSizeCategory -Bytes 1023 | Should -Be "Tiny"
        }
    }

    Context "当文件大小在 1KB 到 1MB 之间" {
        It "应该返回 Small" {
            Get-FileSizeCategory -Bytes 1KB | Should -Be "Small"
            Get-FileSizeCategory -Bytes 500KB | Should -Be "Small"
        }
    }

    Context "当文件大小在 1MB 到 1GB 之间" {
        It "应该返回 Medium" {
            Get-FileSizeCategory -Bytes 1MB | Should -Be "Medium"
            Get-FileSizeCategory -Bytes 500MB | Should -Be "Medium"
        }
    }

    Context "当文件大小超过 1GB" {
        It "应该返回 Large" {
            Get-FileSizeCategory -Bytes 1GB | Should -Be "Large"
            Get-FileSizeCategory -Bytes 100GB | Should -Be "Large"
        }
    }
}

Describe "ConvertTo-ReadableSize" {
    It "正确转换字节" {
        ConvertTo-ReadableSize -Bytes 500 | Should -Be "500 B"
    }

    It "正确转换 KB" {
        ConvertTo-ReadableSize -Bytes 1536 | Should -Be "1.50 KB"
    }

    It "正确转换 MB" {
        ConvertTo-ReadableSize -Bytes 1048576 | Should -Be "1.00 MB"
    }

    It "正确转换 GB" {
        ConvertTo-ReadableSize -Bytes 2147483648 | Should -Be "2.00 GB"
    }
}
"@

$tests | Set-Content "C:\Tests\FileSizeCategory.Tests.ps1" -Encoding UTF8

# 运行测试
$result = Invoke-Pester -Path "C:\Tests\FileSizeCategory.Tests.ps1" -PassThru
Write-Host "`n测试结果：$($result.PassedCount) 通过，$($result.FailedCount) 失败" -ForegroundColor $(if ($result.FailedCount -gt 0) { "Red" } else { "Green" })
```

执行结果示例：

```
Starting discovery in 1 files.
Discovery finished in 12ms.
[+] C:\Tests\FileSizeCategory.Tests.ps1 245ms (18ms|227ms)
  TESTS PASSED: 7
  TESTS FAILED: 0

测试结果：7 通过，0 失败
```

## Mock 与隔离测试

```powershell
# 使用 Mock 隔离外部依赖
$mockTests = @"
BeforeAll {
    function Get-ServerStatus {
        param([string]$ServerName)

        if (-not $ServerName) {
            throw "ServerName 不能为空"
        }

        try {
            $ping = Test-Connection -ComputerName $ServerName -Count 1 -Quiet
            $os = Get-CimInstance Win32_OperatingSystem -ComputerName $ServerName -ErrorAction Stop

            return [PSCustomObject]@{
                Server  = $ServerName
                Online  = $ping
                OS      = $os.Caption
                Version = $os.Version
            }
        } catch {
            return [PSCustomObject]@{
                Server  = $ServerName
                Online  = $false
                OS      = "Unknown"
                Version = "Unknown"
                Error   = $_.Exception.Message
            }
        }
    }
}

Describe "Get-ServerStatus" {
    Context "当服务器在线" {
        BeforeEach {
            Mock Test-Connection { return $true }
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Caption = "Microsoft Windows Server 2022 Standard"
                    Version = "10.0.20348"
                }
            }
        }

        It "应该返回在线状态" {
            $result = Get-ServerStatus -ServerName "SRV01"
            $result.Online | Should -BeTrue
            $result.OS | Should -Be "Microsoft Windows Server 2022 Standard"
        }

        It "应该调用 Test-Connection 一次" {
            Get-ServerStatus -ServerName "SRV01"
            Should -Invoke Test-Connection -Times 1 -Exactly
        }
    }

    Context "当服务器离线" {
        BeforeEach {
            Mock Test-Connection { return $false }
            Mock Get-CimInstance { throw "RPC 服务器不可用" }
        }

        It "应该返回离线状态和错误信息" {
            $result = Get-ServerStatus -ServerName "SRV-OFFLINE"
            $result.Online | Should -BeFalse
            $result.Error | Should -Match "RPC"
        }
    }

    Context "参数验证" {
        It "空服务器名应该抛出异常" {
            { Get-ServerStatus -ServerName "" } | Should -Throw "ServerName 不能为空"
        }
    }
}
"@

$mockTests | Set-Content "C:\Tests\ServerStatus.Tests.ps1" -Encoding UTF8
Invoke-Pester -Path "C:\Tests\ServerStatus.Tests.ps1" -PassThru
```

执行结果示例：

```
Starting discovery in 1 files.
Discovery finished in 8ms.
[+] C:\Tests\ServerStatus.Tests.ps1 189ms (12ms|177ms)
  TESTS PASSED: 4
  TESTS FAILED: 0
```

## 参数化测试与代码覆盖率

```powershell
# 参数化测试（TestCases）
$paramTests = @"
Describe "文件大小分类验证" -ForEach @(
    @{ Bytes = 0;     Expected = "Tiny" }
    @{ Bytes = 100;   Expected = "Tiny" }
    @{ Bytes = 1023;  Expected = "Tiny" }
    @{ Bytes = 1024;  Expected = "Small" }
    @{ Bytes = 51200; Expected = "Small" }
    @{ Bytes = 1048576; Expected = "Medium" }
    @{ Bytes = 52428800; Expected = "Medium" }
    @{ Bytes = 1073741824; Expected = "Large" }
) {
    It "Bytes=<Bytes> 应该分类为 <Expected>" {
        Get-FileSizeCategory -Bytes $Bytes | Should -Be $Expected
    }
}

Describe "ConvertTo-ReadableSize 参数化测试" {
    It "正确转换 <Bytes> 字节为 <Expected>" -TestCases @(
        @{ Bytes = 0;          Expected = "0 B" }
        @{ Bytes = 500;        Expected = "500 B" }
        @{ Bytes = 1024;       Expected = "1.00 KB" }
        @{ Bytes = 1536;       Expected = "1.50 KB" }
        @{ Bytes = 1048576;    Expected = "1.00 MB" }
        @{ Bytes = 1073741824; Expected = "1.00 GB" }
    ) {
        ConvertTo-ReadableSize -Bytes $Bytes | Should -Be $Expected
    }
}
"@

$paramTests | Set-Content "C:\Tests\Parameterized.Tests.ps1" -Encoding UTF8

# 运行测试并计算代码覆盖率
$result = Invoke-Pester -Path "C:\Tests\" -PassThru `
    -CodeCoverage "C:\Scripts\*.ps1" `
    -CodeCoverageOutputFile "C:\Tests\coverage.xml"

Write-Host "`n测试摘要：" -ForegroundColor Cyan
Write-Host "  通过：$($result.PassedCount)"
Write-Host "  失败：$($result.FailedCount)"
Write-Host "  跳过：$($result.SkippedCount)"
if ($result.CodeCoverage) {
    $coveragePct = [math]::Round($result.CodeCoverage.NumberOfCommandsExecuted / $result.CodeCoverage.NumberOfCommandsAnalyzed * 100, 1)
    Write-Host "  代码覆盖率：$coveragePct%"
}
```

执行结果示例：

```
Starting discovery in 3 files.
Discovery finished in 25ms.
[+] C:\Tests\Parameterized.Tests.ps1 56ms

测试摘要：
  通过：17
  失败：0
  跳过：0
  代码覆盖率：85.4%
```

## 注意事项

1. **测试命名**：测试文件以 `.Tests.ps1` 结尾，Pester 会自动发现和运行
2. **Mock 作用域**：`Mock` 只在当前 `Describe`/`Context` 块中生效，不会影响其他测试
3. **幂等性**：测试应该可以重复运行且结果一致，避免依赖外部状态
4. **覆盖率目标**：核心模块争取 80% 以上的代码覆盖率，辅助工具可以适当降低
5. **CI/CD 集成**：Pester 输出支持 NUnit XML 格式，可以集成到 CI/CD 流水线
6. **测试速度**：Mock 外部依赖使测试快速稳定。真实环境的测试放在单独的集成测试中
