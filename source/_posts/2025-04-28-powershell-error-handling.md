---
layout: post
date: 2025-04-28 08:00:00
updated: 2025-04-28 08:00:00
title: "PowerShell 技能连载 - 错误处理与日志最佳实践"
description: PowerTip of the Day - Error Handling and Logging Best Practices in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- error-handling
- logging
- best-practices
---

_适用于 PowerShell 7.0 及以上版本_

在编写生产级 PowerShell 脚本时，错误处理和日志记录往往是最容易被忽视、却又最为关键的环节。一段没有错误处理的脚本，在遇到网络超时、文件缺失或权限不足时，要么静默失败导致后续逻辑产生难以排查的连锁错误，要么直接崩溃让整个自动化流程中断。而缺乏日志的脚本则如同"黑盒"——出了问题只能靠猜测，无法追溯根因。

PowerShell 提供了丰富的错误处理机制，从基础的 `$ErrorActionPreference` 到完善的 `try/catch/finally` 结构，再到自定义错误记录和结构化日志输出。本文将系统性地介绍这些机制，并给出带重试逻辑的健壮脚本模板，帮助你在生产环境中写出更可靠的自动化代码。

<!-- more -->

## 终止错误与非终止错误的区别

PowerShell 将错误分为两类：**终止错误（Terminating Error）**和**非终止错误（Non-Terminating Error）**。理解这两者的区别是正确使用错误处理机制的前提。

- **终止错误**：由 `throw` 语句、`Write-Error -ErrorAction Stop` 或 Cmdlet 的致命故障产生，会中断当前管道和脚本的执行，触发 `catch` 块。
- **非终止错误**：大多数 Cmdlet 在遇到可恢复问题（如删除一个不存在的文件）时产生，默认只写入错误流，脚本继续执行，不会触发 `catch` 块。

下面的示例演示了两种错误的行为差异：

```powershell
# 非终止错误：Remove-Item 找不到文件，但脚本继续执行
Write-Host "=== 非终止错误演示 ==="
Remove-Item -Path "C:\NonExistentFile.txt" -ErrorAction Continue
Write-Host "脚本继续执行，非终止错误不会中断流程"

# 终止错误：throw 会立即中断执行并进入 catch
Write-Host "`n=== 终止错误演示 ==="
try {
    throw "这是一个终止错误，执行将被中断"
    Write-Host "这行不会执行"
}
catch {
    Write-Host "捕获到终止错误: $($_.Exception.Message)"
}
```

```
=== 非终止错误演示 ===
Remove-Item: Cannot find path 'C:\NonExistentFile.txt' because it does not exist.
脚本继续执行，非终止错误不会中断流程

=== 终止错误演示 ===
捕获到终止错误: 这是一个终止错误，执行将被中断
```

可以看到，非终止错误只是输出了一条红色警告，脚本依然继续往下跑；而终止错误则直接跳入了 `catch` 块，`throw` 之后的代码不会执行。

## $ErrorActionPreference 与 -ErrorAction 参数

`$ErrorActionPreference` 是一个全局偏好变量，控制 PowerShell 对非终止错误的默认处理方式。而 `-ErrorAction`（缩写 `-EA`）是 Cmdlet 的通用参数，可以针对单条命令进行覆盖。

常用的值包括：`SilentlyContinue`（静默忽略）、`Continue`（默认，输出错误但继续）、`Stop`（将非终止错误升级为终止错误，触发 `catch`）和`Ignore`（完全忽略且不写入错误流）。

下面的示例展示了如何通过 `-ErrorAction Stop` 将非终止错误转为终止错误，从而被 `try/catch` 捕获：

```powershell
# 默认行为：非终止错误不会被 catch 捕获
Write-Host "=== 默认行为 ==="
try {
    Get-Item -Path "C:\NoSuchFolder\file.txt"
    Write-Host "这行会执行，因为默认是非终止错误"
}
catch {
    Write-Host "不会进入这里"
}

# 使用 -ErrorAction Stop：非终止错误升级为终止错误
Write-Host "`n=== 使用 -ErrorAction Stop ==="
try {
    Get-Item -Path "C:\NoSuchFolder\file.txt" -ErrorAction Stop
    Write-Host "这行不会执行"
}
catch {
    Write-Host "成功捕获: $($_.Exception.Message)"
}

# 全局设置 $ErrorActionPreference
$oldPref = $ErrorActionPreference
$ErrorActionPreference = 'Stop'
Write-Host "`n=== 全局 Stop 偏好 ==="
try {
    Get-Process -Name "NonExistentProcess" -ErrorAction SilentlyContinue
    Write-Host "单条命令 -EA SilentlyContinue 仍可覆盖全局设置"
}
catch {
    Write-Host "不会进入这里"
}
$ErrorActionPreference = $oldPref
```

```
=== 默认行为 ===
Get-Item: Cannot find path 'C:\NoSuchFolder\file.txt' because it does not exist.
这行会执行，因为默认是非终止错误

=== 使用 -ErrorAction Stop ===
成功捕获: Cannot find path 'C:\NoSuchFolder\file.txt' because it does not exist.

=== 全局 Stop 偏好 ===
单条命令 -EA SilentlyContinue 仍可覆盖全局设置
```

**最佳实践**：在需要精确控制错误行为时，优先使用单条命令的 `-ErrorAction` 参数，而非全局修改 `$ErrorActionPreference`。全局修改会影响作用域内所有命令，可能产生意料之外的副作用。

## try/catch/finally 完整结构

`try/catch/finally` 是 PowerShell 中最结构化的错误处理方式。`try` 块中放置可能出错的代码，`catch` 块处理错误，`finally` 块无论是否出错都会执行，通常用于资源清理。

一个常见的误区是：`catch` 只能捕获终止错误。如果你希望捕获某个 Cmdlet 的非终止错误，必须配合 `-ErrorAction Stop` 使用。

```powershell
function Copy-LogFiles {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    try {
        # 验证源目录是否存在
        if (-not (Test-Path -Path $SourcePath)) {
            throw "源目录不存在: $SourcePath"
        }

        # 确保目标目录存在
        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force |
                Out-Null
            Write-Host "已创建目标目录: $DestinationPath"
        }

        # 复制文件，-ErrorAction Stop 确保错误可被捕获
        $files = Get-ChildItem -Path $SourcePath -Filter "*.log" `
            -ErrorAction Stop
        $count = 0

        foreach ($file in $files) {
            Copy-Item -Path $file.FullName -Destination $DestinationPath `
                -Force -ErrorAction Stop
            $count++
        }

        Write-Host "成功复制 $count 个日志文件"
    }
    catch {
        Write-Error "复制日志文件失败: $($_.Exception.Message)"
        # 重新抛出，让调用者也能感知
        throw $_
    }
    finally {
        # 无论成功还是失败，都记录操作时间
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] Copy-LogFiles 操作结束"
    }
}

# 测试：源目录不存在
Copy-LogFiles -SourcePath "C:\NoLogs" -DestinationPath "C:\Backup"
```

```
[2025-04-28 10:30:00] Copy-LogFiles 操作结束
Copy-LogFiles: 复制日志文件失败: 源目录不存在: C:\NoLogs
```

注意 `finally` 块在 `throw` 之前执行了——即使脚本因为 `throw` 而中断，`finally` 中的清理逻辑仍然会运行。这是释放数据库连接、关闭文件句柄等资源清理工作的理想位置。

## 自定义错误记录与错误视图

PowerShell 的 `$Error` 自动变量维护了一个错误列表（最近发生的错误在前）。通过 `ErrorRecord` 对象，我们可以获取丰富的错误上下文信息。此外，PowerShell 允许我们创建自定义的错误记录，以便在模块和大型脚本中提供更精确的错误分类。

```powershell
# 查看最近一次错误的详细信息
try {
    Get-Process -Name "DefinitelyNotARealProcess" -ErrorAction Stop
}
catch {
    $err = $_
    Write-Host "错误类型: $($err.CategoryInfo.Category)"
    Write-Host "错误原因: $($err.CategoryInfo.Reason)"
    Write-Host "目标对象: $($err.TargetObject)"
    Write-Host "完整消息: $($err.Exception.Message)"
    Write-Host "脚本堆栈: $($err.ScriptStackTrace)"
}

# 创建自定义错误记录
Write-Host "`n=== 自定义错误记录 ==="
$exception = [System.InvalidOperationException]::new(
    "配置文件版本不兼容，要求 v2.0，实际 v1.3"
)
$errorRecord = [System.Management.Automation.ErrorRecord]::new(
    $exception,
    "ConfigVersionMismatch",       # ErrorId
    [System.Management.Automation.ErrorCategory]::InvalidData,
    "config-v1.3"                  # TargetObject
)

Write-Host "自定义 ErrorId: $($errorRecord.FullyQualifiedErrorId)"
Write-Host "错误类别: $($errorRecord.CategoryInfo.Category)"
Write-Host "目标对象: $($errorRecord.TargetObject)"
```

```
错误类型: ObjectNotFound
错误原因: Get-Process
目标对象: DefinitelyNotARealProcess
完整消息: Cannot find a process with the name 'DefinitelyNotARealProcess'.
脚本堆栈: at <ScriptBlock>, <No file>: line 2

=== 自定义错误记录 ===
自定义 ErrorId: ConfigVersionMismatch
错误类别: InvalidData
目标对象: config-v1.3
```

自定义错误记录在编写可复用模块时特别有用。通过 `FullyQualifiedErrorId`，调用方可以精确地针对特定错误类型编写处理逻辑，而非依赖模糊的字符串匹配。

## 结构化日志输出

在生产环境中，零散的 `Write-Host` 输出很难被日志收集系统（如 ELK、Splunk）解析。结构化日志（Structured Logging）将每条日志输出为 JSON 格式，便于集中存储、检索和告警。

下面的函数封装了一个轻量级的结构化日志写入器，支持控制台彩色输出和 JSON 文件追加两种模式：

```powershell
function Write-StructuredLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',

        [string]$LogPath = "$PSScriptRoot\app.log.json",

        [hashtable]$ExtraData = @{}
    )

    $entry = [ordered]@{
        timestamp = (Get-Date).ToString("o")
        level     = $Level
        message   = $Message
        script    = $MyInvocation.ScriptName
        line      = $MyInvocation.ScriptLineNumber
    }

    # 合并额外数据
    foreach ($key in $ExtraData.Keys) {
        $entry[$key] = $ExtraData[$key]
    }

    $jsonLine = $entry | ConvertTo-Json -Compress

    # 控制台带颜色输出
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN'  { 'Yellow' }
        'DEBUG' { 'Gray' }
        default { 'White' }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color

    # 追加到 JSON 日志文件（每行一个 JSON 对象）
    $jsonLine | Add-Content -Path $LogPath -Encoding UTF8
}

# 使用示例
Write-StructuredLog -Message "开始执行数据同步" -Level 'INFO' `
    -ExtraData @{ source = "DB-01"; records = 1500 }

Write-StructuredLog -Message "连接超时，准备重试" -Level 'WARN' `
    -ExtraData @{ server = "api.example.com"; attempt = 1 }

Write-StructuredLog -Message "数据校验失败" -Level 'ERROR' `
    -ExtraData @{ table = "Orders"; failedRows = 23 }
```

```
[INFO] 开始执行数据同步
[WARN] 连接超时，准备重试
[ERROR] 数据校验失败
```

日志文件中每行是一个独立的 JSON 对象，这种格式（JSON Lines / NDJSON）可以直接被 `jq`、`ConvertFrom-Json` 或任何日志平台解析，无需处理嵌套数组结构。

## 带重试逻辑的健壮脚本模板

在真实的运维场景中，网络抖动、服务暂时不可用等问题是常态。一个健壮的脚本应该具备自动重试能力，而不是遇到第一次失败就放弃。下面的模板将 `try/catch`、结构化日志和指数退避重试整合在一起：

```powershell
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Action,

        [string]$Description = "操作",

        [int]$MaxRetries = 3,

        [int]$BaseDelaySeconds = 2,

        [double]$BackoffMultiplier = 2.0
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Host "[$attempt/$MaxRetries] 正在执行: $Description"
            $result = & $Action
            Write-Host "[$attempt/$MaxRetries] 执行成功" `
                -ForegroundColor Green
            return $result
        }
        catch {
            $lastError = $_
            $delay = $BaseDelaySeconds *
                [Math]::Pow($BackoffMultiplier, $attempt - 1)

            Write-Host ("[$attempt/$MaxRetries] 执行失败: " +
                "$($_.Exception.Message)") -ForegroundColor Red

            if ($attempt -lt $MaxRetries) {
                Write-Host "  等待 $delay 秒后重试..." `
                    -ForegroundColor Yellow
                Start-Sleep -Seconds $delay
            }
        }
    }

    # 所有重试均失败
    Write-Host "已达到最大重试次数 ($MaxRetries)，操作终止" `
        -ForegroundColor Red
    throw $lastError
}

# 使用示例：调用一个可能失败的 API
$result = Invoke-WithRetry -Description "调用用户数据接口" `
    -MaxRetries 3 -BaseDelaySeconds 2 -BackoffMultiplier 2.0 `
    -Action {
        $response = Invoke-RestMethod `
            -Uri "https://api.example.com/users" `
            -TimeoutSec 10 `
            -ErrorAction Stop
        return $response
    }

Write-Host "获取到 $($result.Count) 条用户记录"
```

```
[1/3] 正在执行: 调用用户数据接口
[1/3] 执行失败: The operation has timed out.
  等待 2 秒后重试...
[2/3] 正在执行: 调用用户数据接口
[2/3] 执行失败: The operation has timed out.
  等待 4 秒后重试...
[3/3] 正在执行: 调用用户数据接口
[3/3] 执行成功
获取到 42 条用户记录
```

指数退避（Exponential Backoff）的等待时间递增规律为：2s、4s、8s......这样做的好处是给远程服务足够的恢复时间，同时在首次失败后不会等太久。如果所有重试都失败，最后的 `throw` 确保错误会向上传递，调用方可以决定是否继续或中止整个流程。

## 综合实战：带日志和重试的文件同步脚本

将前面介绍的所有技术整合起来，下面是一个完整的文件同步脚本，涵盖结构化日志、`try/catch/finally`、`-ErrorAction Stop` 和重试逻辑：

```powershell
function Sync-LogDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination,

        [int]$MaxRetries = 3
    )

    $syncResult = [ordered]@{
        startTime    = $null
        endTime      = $null
        copiedFiles  = 0
        failedFiles  = 0
        skippedFiles = 0
    }

    try {
        $syncResult.startTime = Get-Date -Format "o"

        # 验证源路径
        if (-not (Test-Path -Path $Source -ErrorAction Stop)) {
            throw "源路径不存在: $Source"
        }

        # 确保目标目录存在
        $null = New-Item -ItemType Directory -Path $Destination `
            -Force -ErrorAction Stop

        $files = Get-ChildItem -Path $Source -Filter "*.log" `
            -Recurse -ErrorAction Stop

        foreach ($file in $files) {
            $destFile = Join-Path $Destination $file.Name

            # 跳过已存在且未修改的文件
            if ((Test-Path $destFile) -and
                ($file.LastWriteTime -le
                 (Get-Item $destFile).LastWriteTime)) {
                $syncResult.skippedFiles++
                continue
            }

            # 带重试的文件复制
            try {
                Invoke-WithRetry -Description "复制 $($file.Name)" `
                    -MaxRetries $MaxRetries -Action {
                        Copy-Item -Path $file.FullName `
                            -Destination $destFile -Force `
                            -ErrorAction Stop
                    }
                $syncResult.copiedFiles++
            }
            catch {
                Write-Host "跳过文件 $($file.Name): " +
                    "$($_.Exception.Message)" -ForegroundColor Yellow
                $syncResult.failedFiles++
            }
        }
    }
    catch {
        Write-Host "同步过程中发生致命错误: " +
            "$($_.Exception.Message)" -ForegroundColor Red
        throw
    }
    finally {
        $syncResult.endTime = Get-Date -Format "o"
        Write-Host "`n--- 同步报告 ---"
        Write-Host ("开始时间: $($syncResult.startTime)")
        Write-Host ("结束时间: $($syncResult.endTime)")
        Write-Host ("复制成功: $($syncResult.copiedFiles) 个文件")
        Write-Host ("复制失败: $($syncResult.failedFiles) 个文件")
        Write-Host ("跳过文件: $($syncResult.skippedFiles) 个文件")
    }
}

# 执行同步
Sync-LogDirectory -Source "C:\Logs\App" `
    -Destination "D:\Backup\Logs"
```

```
[1/3] 正在执行: 复制 app-2025-04-27.log
[1/3] 执行成功
[1/3] 正在执行: 复制 app-2025-04-28.log
[1/3] 执行成功

--- 同步报告 ---
开始时间: 2025-04-28T10:15:00.0000000
结束时间: 2025-04-28T10:15:03.0000000
复制成功: 2 个文件
复制失败: 0 个文件
跳过文件: 5 个文件
```

这个脚本的核心设计思路是：外层 `try/catch` 处理整体流程的致命错误（如源路径不存在），内层 `try/catch` 处理单个文件的可恢复错误（跳过失败文件继续处理其余文件），`finally` 始终输出统计报告。这种"外层致命、内层宽容"的错误处理策略在批量操作场景中非常实用。

## 注意事项

1. **`-ErrorAction Stop` 是连接非终止错误与 `try/catch` 的桥梁**：忘记加这个参数是最常见的错误处理遗漏，导致 `catch` 块形同虚设。
2. **避免在 `catch` 中吞掉错误**：如果 `catch` 块只是 `Write-Host` 而不 `throw`，调用方将无法感知失败。除非你明确要忽略某个已知错误，否则应当重新抛出。
3. **`$Error` 列表会不断增长**：PowerShell 的 `$Error` 自动变量最多保留 256 条（可通过 `$MaximumErrorCount` 调整），在长时间运行的脚本中注意不要过度依赖它的顺序。
4. **结构化日志的文件写入考虑并发**：多进程同时写入同一个日志文件可能导致内容交错。在高并发场景下，考虑使用文件锁或集中式日志服务。
5. **重试次数和退避策略需要根据场景调整**：网络请求适合短间隔多次重试，数据库操作可能需要更长间隔。盲目重试可能加剧服务端压力。
6. **`finally` 块中避免抛出异常**：如果 `finally` 中的代码也可能失败，务必用嵌套的 `try/catch` 保护，否则会掩盖原始错误。
