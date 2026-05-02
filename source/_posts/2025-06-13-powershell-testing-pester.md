---
layout: post
date: 2025-06-13 08:00:00
updated: 2025-06-13 08:00:00
title: "PowerShell 技能连载 - Pester 测试框架"
description: PowerTip of the Day - Pester Testing Framework in PowerShell
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
- tdd
---

_适用于 PowerShell 5.1 及以上版本，建议安装 Pester 5.x_

基础设施即代码（IaC）和自动化脚本的普及使得"测试"不再只是开发者的专利。Pester 是 PowerShell 社区最流行的测试框架，它使用 BDD（行为驱动开发）风格的语法编写测试——描述期望行为、执行代码、验证结果。无论是验证函数逻辑、测试配置是否符合预期，还是构建运维合规检查，Pester 都是不可或缺的工具。

本文将讲解 Pester 的核心语法、常用模式，以及如何构建运维合规测试。

<!-- more -->

## 安装与基础语法

```powershell
# 安装 Pester 5.x
Install-Module -Name Pester -Scope CurrentUser -Force -SkipPublisherCheck

# 验证版本
Get-Module Pester -ListAvailable | Select-Object Name, Version

# 基础测试结构
$testScript = @'
Describe "数学运算测试" {
    Context "加法" {
        It "1 + 1 应该等于 2" {
            (1 + 1) | Should -Be 2
        }

        It "负数加法应该正确" {
            (-3) + 5 | Should -Be 2
        }
    }

    Context "字符串操作" {
        It "字符串应该包含子串" {
            "Hello World" | Should -BeLike "*World*"
        }

        It "字符串长度应该正确" {
            "PowerShell".Length | Should -Be 10
        }
    }
}
'@

Invoke-Pester -ScriptBlock ([scriptblock]::Create($testScript)) -Output Detailed
```

执行结果示例：

```
Describing 数学运算测试
  Context 加法
    [+] 1 + 1 应该等于 2 15ms
    [+] 负数加法应该正确 3ms
  Context 字符串操作
    [+] 字符串应该包含子串 8ms
    [+] 字符串长度应该正确 2ms

Tests passed: 4, Failed: 0, Skipped: 0
```

## 测试自定义函数

```powershell
# 被测函数
function Get-FileSizeCategory {
    param([long]$SizeBytes)

    if ($SizeBytes -lt 1KB) { return 'Tiny' }
    if ($SizeBytes -lt 1MB) { return 'Small' }
    if ($SizeBytes -lt 1GB) { return 'Medium' }
    if ($SizeBytes -lt 1TB) { return 'Large' }
    return 'Huge'
}

# 测试文件
Describe "Get-FileSizeCategory" {
    Context "小文件" {
        It "0 字节应该返回 Tiny" {
            Get-FileSizeCategory -SizeBytes 0 | Should -Be 'Tiny'
        }

        It "1023 字节应该返回 Tiny" {
            Get-FileSizeCategory -SizeBytes 1023 | Should -Be 'Tiny'
        }
    }

    Context "边界值测试" {
        It "1KB 恰好应该是 Small" {
            Get-FileSizeCategory -SizeBytes 1KB | Should -Be 'Small'
        }

        It "1MB - 1 应该是 Small" {
            Get-FileSizeCategory -SizeBytes (1MB - 1) | Should -Be 'Small'
        }

        It "1MB 应该是 Medium" {
            Get-FileSizeCategory -SizeBytes 1MB | Should -Be 'Medium'
        }
    }

    Context "异常输入" {
        It "负数应该抛出异常" {
            { Get-FileSizeCategory -SizeBytes -1 } | Should -Throw
        }
    }
}

# 运行测试
Invoke-Pester -Output Detailed
```

执行结果示例：

```
Describing Get-FileSizeCategory
  Context 小文件
    [+] 0 字节应该返回 Tiny 12ms
    [+] 1023 字节应该返回 Tiny 3ms
  Context 边界值测试
    [+] 1KB 恰好应该是 Small 2ms
    [+] 1MB - 1 应该是 Small 2ms
    [+] 1MB 应该是 Medium 2ms

Tests passed: 5, Failed: 0
```

## 运维合规测试

Pester 最强大的运维场景是基础设施合规检查——验证服务器配置是否符合安全基线：

```powershell
# 合规检查测试文件
Describe "Windows 安全基线检查" {
    Context "执行策略" {
        It "执行策略不应为 Unrestricted" {
            $policy = Get-ExecutionPolicy
            $policy | Should -Not -Be 'Unrestricted'
        }

        It "应使用 RemoteSigned 或更严格的策略" {
            $policy = Get-ExecutionPolicy
            @('RemoteSigned', 'AllSigned', 'Restricted') | Should -Contain $policy
        }
    }

    Context "防火墙状态" {
        It "域配置文件防火墙应启用" {
            $fw = Get-NetFirewallProfile -Profile Domain
            $fw.Enabled | Should -BeTrue
        }

        It "专用配置文件防火墙应启用" {
            $fw = Get-NetFirewallProfile -Profile Private
            $fw.Enabled | Should -BeTrue
        }

        It "公用配置文件防火墙应启用" {
            $fw = Get-NetFirewallProfile -Profile Public
            $fw.Enabled | Should -BeTrue
        }
    }

    Context "磁盘空间" {
        It "系统盘可用空间应大于 10GB" {
            $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $freeGB | Should -BeGreaterThan 10
        }
    }

    Context "安全更新" {
        It "应在最近 30 天内安装过更新" {
            $latestPatch = Get-CimInstance Win32_QuickFixEngineering |
                Sort-Object InstalledOn -Descending |
                Select-Object -First 1
            ($latestPatch.InstalledOn) | Should -BeGreaterThan (Get-Date).AddDays(-30)
        }
    }

    Context "密码策略" {
        It "最小密码长度应至少 8 位" {
            $policy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
            if ($policy) {
                $policy.MinPasswordLength | Should -BeGreaterOrEqual 8
            }
        }
    }
}

# 运行合规检查并生成报告
$config = New-PesterConfiguration
$config.Output.Verbosity = 'Detailed'
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "C:\Reports\compliance-results.xml"

Invoke-Pester -Configuration $config
```

执行结果示例：

```
Describing Windows 安全基线检查
  Context 执行政策
    [+] 执行政策不应为 Unrestricted 15ms
  Context 防火墙状态
    [+] 域配置文件防火墙应启用 8ms
    [+] 专用配置文件防火墙应启用 5ms
    [-] 公用配置文件防火墙应启用 45ms
        Expected $true, but got $false.
  Context 磁盘空间
    [+] 系统盘可用空间应大于 10GB 12ms

Tests passed: 6, Failed: 1, Skipped: 0
```

## Mock 和 Stub

Pester 支持 Mock 功能，可以替换外部依赖进行隔离测试：

```powershell
function Get-ServerStatus {
    param([string]$ServerName)

    try {
        $response = Invoke-RestMethod -Uri "https://$ServerName/health" -TimeoutSec 5
        return $response.status
    } catch {
        return "Unreachable"
    }
}

Describe "Get-ServerStatus" {
    BeforeAll {
        # Mock Invoke-RestMethod
        Mock Invoke-RestMethod {
            return @{ status = "healthy" }
        } -ParameterFilter { $Uri -match 'web-01' }

        Mock Invoke-RestMethod {
            return @{ status = "degraded" }
        } -ParameterFilter { $Uri -match 'db-01' }

        Mock Invoke-RestMethod {
            throw "Connection timeout"
        } -ParameterFilter { $Uri -match 'legacy' }
    }

    It "正常服务器应返回 healthy" {
        Get-ServerStatus -ServerName "web-01" | Should -Be "healthy"
    }

    It "降级服务器应返回 degraded" {
        Get-ServerStatus -ServerName "db-01" | Should -Be "degraded"
    }

    It "不可达服务器应返回 Unreachable" {
        Get-ServerStatus -ServerName "legacy-server" | Should -Be "Unreachable"
    }

    It "应该调用 Invoke-RestMethod" {
        Get-ServerStatus -ServerName "web-01" | Out-Null
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }
}
```

执行结果示例：

```
Describing Get-ServerStatus
  [+] 正常服务器应返回 healthy 8ms
  [+] 降级服务器应返回 degraded 3ms
  [+] 不可达服务器应返回 Unreachable 2ms
  [+] 应该调用 Invoke-RestMethod 15ms

Tests passed: 4, Failed: 0
```

## 注意事项

1. **Pester 5.x 语法**：Pester 5 有重大语法变更（如 `Context` 内不支持直接写 `It` 外的代码），从 Pester 4 升级需注意
2. **测试隔离**：每个 `It` 块应该是独立的，不依赖其他测试的执行顺序。使用 `BeforeAll`/`BeforeEach` 初始化状态
3. **Mock 作用域**：Mock 只在当前 `Describe`/`Context` 块内生效，不会影响外部代码
4. **CI/CD 集成**：Pester 的 NUnit XML 输出可以直接被 Azure DevOps、GitHub Actions 等解析展示
5. **测试命名**：`It` 的描述字符串应该清晰表达期望行为，失败时可直接从报告看出问题
6. **覆盖率**：Pester 不直接提供代码覆盖率，但可以结合 `Invoke-CoverageAnalysis` 等工具实现
