---
layout: post
date: 2025-10-02 08:00:00
updated: 2025-10-02 08:00:00
title: "PowerShell 技能连载 - 错误处理模式"
description: PowerTip of the Day - Error Handling Patterns in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- error-handling
- try-catch
- best-practices
---

_适用于 PowerShell 5.1 及以上版本_

<!-- more -->

## 背景

在编写 PowerShell 脚本时，错误处理往往是被忽视的环节。很多开发者习惯性地依赖默认的错误输出，直到脚本在无人值守的生产环境中意外崩溃才开始重视。PowerShell 提供了丰富的错误处理机制，从简单的 `-ErrorAction` 参数到完整的 `try/catch/finally` 结构，再到 `$Error` 自动变量的深度利用，每一种机制都有其最佳适用场景。

掌握错误处理模式不仅能提升脚本的健壮性，还能让运维人员更快地定位问题根因。本文将介绍三种最常见的错误处理模式：基本的 try/catch 模式、批量操作的容错模式以及错误日志收集模式，帮助你在不同场景下选择最合适的策略。

## 模式一：基本的 try/catch/finally 模式

`try/catch/finally` 是最经典的错误处理结构。`try` 块中放置可能出错的操作，`catch` 块中处理异常，`finally` 块无论是否出错都会执行，适合做资源清理。

需要注意，PowerShell 默认的"非终止错误"不会被 `catch` 捕获。必须将 `ErrorAction` 设置为 `Stop`，将非终止错误提升为终止错误，`catch` 才能生效。

```powershell
function Copy-LogArchive {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    try {
        Write-Host "开始复制日志归档文件..."
        $sourceItem = Get-Item -Path $SourcePath -ErrorAction Stop

        if (-not $sourceItem.Exists) {
            throw "源文件不存在: $SourcePath"
        }

        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
        Write-Host "文件复制成功: $DestinationPath"
    }
    catch [System.IO.FileNotFoundException] {
        Write-Error "文件未找到异常: $($_.Exception.Message)"
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "权限不足: $($_.Exception.Message)"
    }
    catch {
        Write-Error "未知错误: $($_.Exception.Message)"
        Write-Host "异常类型: $($_.Exception.GetType().FullName)"
    }
    finally {
        Write-Host "操作完成，清理临时资源..."
    }
}

Copy-LogArchive -SourcePath "C:\Logs\app-2025.zip" -DestinationPath "D:\Backup\app-2025.zip"
```

执行结果示例：

```
开始复制日志归档文件...
文件未找到异常: 找不到路径"C:\Logs\app-2025.zip"，因为该路径不存在。
操作完成，清理临时资源...
```

## 模式二：批量操作的容错模式

在批量处理大量对象时（比如遍历数百台服务器或上千个文件），不希望某一个对象的失败导致整个操作中断。此时应使用 `foreach` 循环配合 `try/catch`，让每个对象独立处理，并记录成功与失败的统计信息。

```powershell
$computers = @(
    "SRV-WEB01",
    "SRV-DB01",
    "SRV-APP01",
    "SRV-FILE01",
    "SRV-MAIL01"
)

$successList = [System.Collections.Generic.List[string]]::new()
$failList = [System.Collections.Generic.List[string]]::new()

foreach ($computer in $computers) {
    try {
        $session = New-PSSession -ComputerName $computer -ErrorAction Stop

        $result = Invoke-Command -Session $session -ScriptBlock {
            Get-Service -Name "WinRM" | Select-Object Name, Status, StartType
        } -ErrorAction Stop

        Write-Host "[$computer] WinRM 状态: $($result.Status)" -ForegroundColor Green
        $successList.Add($computer)

        Remove-PSSession -Session $session
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Host "[$computer] 连接失败: $errorMsg" -ForegroundColor Red
        $failList.Add("${computer}: ${errorMsg}")
    }
}

Write-Host "`n===== 批量操作汇总 ====="
Write-Host "成功: $($successList.Count) 台"
Write-Host "失败: $($failList.Count) 台"

if ($failList.Count -gt 0) {
    Write-Host "`n失败详情:" -ForegroundColor Yellow
    foreach ($item in $failList) {
        Write-Host "  - $item"
    }
}
```

执行结果示例：

```
[SRV-WEB01] WinRM 状态: Running
[SRV-DB01] 连接失败: 连接到远程服务器 SRV-DB01 失败。
[SRV-APP01] WinRM 状态: Running
[SRV-FILE01] 连接失败: 拒绝访问。
[SRV-MAIL01] WinRM 状态: Stopped

===== 批量操作汇总 =====
成功: 3 台
失败: 2 台

失败详情:
  - SRV-DB01: 连接到远程服务器 SRV-DB01 失败。
  - SRV-FILE01: 拒绝访问。
```

## 模式三：结构化错误日志收集模式

在复杂脚本或自动化流水线中，仅靠控制台输出远远不够。我们需要将错误信息以结构化方式记录下来，便于后续分析和审计。下面的模式使用自定义错误记录对象，在脚本执行结束后统一输出 JSON 格式的错误报告。

```powershell
$logEntries = [System.Collections.Generic.List[PSObject]]::new()

function Write-OperationLog {
    param(
        [string]$Operation,
        [string]$Target,
        [string]$Status,
        [string]$Message = ""
    )

    $entry = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Operation = $Operation
        Target    = $Target
        Status    = $Status
        Message   = $Message
    }

    $logEntries.Add($entry)
}

$services = @("Spooler", "WinRM", "wuauserv", "NonExistSvc", "BITS")

foreach ($svc in $services) {
    try {
        $service = Get-Service -Name $svc -ErrorAction Stop
        Restart-Service -InputObject $service -Force -ErrorAction Stop
        Write-OperationLog -Operation "Restart-Service" -Target $svc -Status "Success"
        Write-Host "[OK] $svc 已重启" -ForegroundColor Green
    }
    catch {
        Write-OperationLog -Operation "Restart-Service" -Target $svc -Status "Failed" -Message $_.Exception.Message
        Write-Host "[FAIL] $svc 失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

$report = $logEntries | ConvertTo-Json -Depth 3
$reportPath = Join-Path $env:TEMP "service-operation-report.json"
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`n报告已保存至: $reportPath"
Write-Host "总记录数: $($logEntries.Count)"
Write-Host "失败记录: $(($logEntries | Where-Object { $_.Status -eq 'Failed' }).Count)"
```

执行结果示例：

```
[OK] Spooler 已重启
[OK] WinRM 已重启
[FAIL] wuauserv 失败: 无法打开"Windows Update"服务。
[FAIL] NonExistSvc 失败: 找不到任何服务名称为"NonExistSvc"的服务。
[OK] BITS 已重启

报告已保存至: /tmp/service-operation-report.json
总记录数: 5
失败记录: 2
```

## 模式四：错误类型筛选与重试模式

在生产环境中，某些操作可能因瞬时故障（如网络抖动、数据库连接超时）而失败，这种情况下自动重试比直接报错更合理。下面的模式根据异常类型决定是否重试，并设置最大重试次数和退避间隔。

```powershell
function Invoke-WebRequestWithRetry {
    param(
        [string]$Url,
        [int]$MaxRetries = 3,
        [int]$RetryIntervalSeconds = 2
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Host "第 $attempt 次请求: $Url"
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
            Write-Host "请求成功，状态码: $($response.StatusCode)" -ForegroundColor Green
            return $response
        }
        catch [System.Net.WebException] {
            $lastError = $_
            $statusCode = $_.Exception.Response.StatusCode

            if ($statusCode -ge 400 -and $statusCode -lt 500) {
                Write-Host "客户端错误 ($statusCode)，不重试。" -ForegroundColor Red
                throw $_
            }

            Write-Host "服务端/网络错误，${RetryIntervalSeconds}s 后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds $RetryIntervalSeconds
            $RetryIntervalSeconds = $RetryIntervalSeconds * 2
        }
        catch {
            $lastError = $_
            Write-Host "非网络异常: $($_.Exception.Message)" -ForegroundColor Red
            throw $_
        }
    }

    Write-Host "已达最大重试次数 ($MaxRetries)，操作失败。" -ForegroundColor Red
    throw $lastError
}

Invoke-WebRequestWithRetry -Url "https://httpbin.org/status/500" -MaxRetries 3
```

执行结果示例：

```
第 1 次请求: https://httpbin.org/status/500
服务端/网络错误，2s 后重试...
第 2 次请求: https://httpbin.org/status/500
服务端/网络错误，4s 后重试...
第 3 次请求: https://httpbin.org/status/500
已达最大重试次数 (3)，操作失败。
Invoke-WebRequestWithRetry: 远程服务器返回错误: (500) 内部服务器错误。
```

## 注意事项

1. **区分终止错误与非终止错误**：PowerShell 中大多数 cmdlet 产生的是非终止错误（Non-Terminating Error），默认不会触发 `catch`。务必在 cmdlet 后添加 `-ErrorAction Stop` 参数，或通过 `$ErrorActionPreference = 'Stop'` 全局设置，才能让 `try/catch` 正常工作。

2. **不要滥用空 catch 块**：空的 `catch {}` 会静默吞掉所有错误，让排错变得极其困难。即使在不需要特殊处理的场景下，也应至少记录一行日志，比如 `Write-Warning "操作失败: $($_.Exception.Message)"`。

3. **善用 catch 的类型过滤**：`catch` 可以指定具体的异常类型（如 `[System.IO.FileNotFoundException]`），先捕获具体异常，最后用通用的 `catch {}` 兜底。多个 `catch` 块按照从具体到通用的顺序排列。

4. **finally 块用于资源释放**：无论是否发生异常，`finally` 块都会执行。适合关闭数据库连接、移除临时文件、释放 PSSession 等清理工作。即使 `try` 中有 `return` 语句，`finally` 也会在返回前执行。

5. **$Error 自动变量保留历史记录**：PowerShell 的 `$Error` 数组自动收集所有会话中的错误，最新错误在索引 0。可以通过 `$Error[0] | Format-List *` 查看完整的错误详情，包括脚本堆栈追踪（**ScriptStackTrace**）。

6. **批量操作避免管道中的 try/catch**：在管道（`|`）中使用 `ForEach-Object` 嵌套 `try/catch` 会导致代码难以阅读和调试。推荐改用 `foreach` 语句，结构更清晰，也更容易添加计数器和日志收集逻辑。
