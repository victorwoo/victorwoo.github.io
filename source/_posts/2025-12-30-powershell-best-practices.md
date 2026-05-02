---
layout: post
date: 2025-12-30 08:00:00
updated: 2025-12-30 08:00:00
title: "PowerShell 技能连载 - 脚本最佳实践"
description: PowerTip of the Day - PowerShell Scripting Best Practices
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- best-practices
- code-quality
- maintainability
---

_适用于 PowerShell 5.1 及以上版本_

回顾这一年的技能连载，我们从基础命令一路走到了高级自动化场景。在实际生产环境中，能跑通一段脚本只是起点，让脚本在面对异常输入、网络波动、权限变更时依然稳定运行，才是工程师的真正功力。今天我们就来系统梳理 PowerShell 脚本编写的最佳实践。

这些实践并非教条，而是从大量生产故障中提炼出来的经验总结。遵循它们可以让你的脚本更健壮、更易维护，也让接手代码的同事少踩几个坑。无论你是刚入门的新手还是资深运维工程师，这些原则都值得时刻对照。

<!-- more -->

## 代码结构与命名规范

良好的命名和结构是可维护脚本的基石。PowerShell 社区有一套广泛接受的动词-名词命名约定，遵循它能让你的函数与内置 cmdlet 保持一致的调用体验。同时，参数验证、类型约束和结构化注释也是专业脚本的标配。

```powershell
<#
.SYNOPSIS
    获取指定路径下的文件大小统计信息
.DESCRIPTION
    递归扫描目标目录，返回按扩展名分类的文件大小汇总
.PARAMETER Path
    要扫描的目录路径，必须存在且可访问
.PARAMETER TopN
    返回最大的 N 种文件类型，默认为 10
.EXAMPLE
    Get-FileStatistics -Path "C:\Logs" -TopN 5
#>
function Get-FileStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "指定的路径不存在或不是目录: $_"
            }
            $true
        })]
        [string]$Path,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$TopN = 10
    )

    begin {
        # 记录开始时间，用于性能统计
        $startTime = Get-Date
        Write-Verbose "开始扫描目录: $Path"
    }

    process {
        $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue

        $stats = $files |
            Group-Object Extension |
            Sort-Object Count -Descending |
            Select-Object -First $TopN |
            ForEach-Object {
                [PSCustomObject]@{
                    Extension = $_.Name
                    Count     = $_.Count
                    TotalSizeMB = [math]::Round(
                        ($_.Group | Measure-Object Length -Sum).Sum / 1MB,
                        2
                    )
                }
            }

        $stats
    }

    end {
        $elapsed = (Get-Date) - $startTime
        Write-Verbose "扫描完成，耗时: $($elapsed.TotalSeconds.ToString('F2')) 秒"
    }
}

# 调用示例
Get-FileStatistics -Path "/var/log" -TopN 5 -Verbose
```

执行结果示例：

```
VERBOSE: 开始扫描目录: /var/log
VERBOSE: 扫描完成，耗时: 0.34 秒

Extension Count TotalSizeMB
--------- ----- -----------
.log      128   256.45
.gz       42    1024.80
.json     18    12.30
.txt      7     3.15
.err      3     0.85
```

上面的代码展示了几个关键实践：函数名使用-approved动词加名词的形式，参数加了 `[CmdletBinding]` 和完整的验证属性，并用基于注释的帮助文档让 `Get-Help` 能直接识别。`begin/process/end` 块的划分让管道处理逻辑更清晰。

## 错误处理与防御性编程

脚本在开发环境能跑通很容易，但生产环境充满了意外：磁盘满、网络断、权限不足、文件被占用。防御性编程的核心理念是"永远假设会出错"，然后用结构化的方式处理每一个可能的失败点。

```powershell
function Copy-LogArchive {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [Parameter()]
        [int]$RetryCount = 3,

        [Parameter()]
        [int]$RetryDelaySeconds = 5
    )

    # 前置检查：源路径是否存在
    if (-not (Test-Path $SourcePath)) {
        Write-Error "源路径不存在: $SourcePath"
        return
    }

    # 确保目标目录存在
    if (-not (Test-Path $DestinationPath)) {
        if ($PSCmdlet.ShouldProcess($DestinationPath, "创建目标目录")) {
            try {
                New-Item -Path $DestinationPath -ItemType Directory -Force |
                    Out-Null
                Write-Verbose "已创建目标目录: $DestinationPath"
            }
            catch {
                Write-Error "无法创建目标目录: $_"
                return
            }
        }
    }

    # 获取待复制的文件列表
    $files = @(Get-ChildItem -Path $SourcePath -File -Filter "*.log")

    if ($files.Count -eq 0) {
        Write-Warning "源目录中没有 .log 文件，操作跳过"
        return
    }

    $copiedCount = 0
    $failedFiles = @()

    foreach ($file in $files) {
        $destFile = Join-Path $DestinationPath $file.Name
        $attempt = 0
        $success = $false

        while ($attempt -lt $RetryCount -and -not $success) {
            $attempt++
            try {
                if ($PSCmdlet.ShouldProcess($file.FullName, "复制到 $DestinationPath")) {
                    Copy-Item -Path $file.FullName -Destination $destFile -Force
                    $copiedCount++
                    $success = $true
                    Write-Verbose "[$attempt/$RetryCount] 复制成功: $($file.Name)"
                }
            }
            catch {
                Write-Warning "[$attempt/$RetryCount] 复制失败: $($file.Name) - $($_.Exception.Message)"
                if ($attempt -lt $RetryCount) {
                    Write-Verbose "等待 $RetryDelaySeconds 秒后重试..."
                    Start-Sleep -Seconds $RetryDelaySeconds
                }
                else {
                    $failedFiles += $file.Name
                }
            }
        }
    }

    # 汇总报告
    $report = [PSCustomObject]@{
        TotalFiles    = $files.Count
        CopiedFiles   = $copiedCount
        FailedFiles   = $failedFiles.Count
        FailedList    = $failedFiles -join ", "
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    if ($failedFiles.Count -gt 0) {
        Write-Warning "部分文件复制失败: $($failedFiles -join ', ')"
    }

    $report
}

# 调用示例
Copy-LogArchive -SourcePath "C:\Logs\App" -DestinationPath "\\Server\Backup\Logs" -RetryCount 3 -Verbose
```

执行结果示例：

```
VERBOSE: 已创建目标目录: \\Server\Backup\Logs
VERBOSE: [1/3] 复制成功: app-2025-12-28.log
VERBOSE: [1/3] 复制成功: app-2025-12-29.log
WARNING: [1/3] 复制失败: app-2025-12-30.log - 被其他进程占用。
VERBOSE: 等待 5 秒后重试...
VERBOSE: [2/3] 复制成功: app-2025-12-30.log

TotalFiles  : 3
CopiedFiles : 3
FailedFiles : 0
FailedList  :
Timestamp   : 2025-12-30 10:15:30
```

这个函数体现了多层防御：前置检查确保输入合法，重试机制应对瞬态故障，`SupportsShouldProcess` 提供 `-WhatIf` 和 `-Confirm` 支持，汇总报告让运维人员一眼看清执行结果。特别注意 `@(...)` 包裹管道赋值，这确保即使没有文件也返回空数组而非 `$null`，避免后续 `Count` 属性报错。

## 性能优化与安全编码

当脚本处理的文件从几十个变成几万个，或者从单机扩展到数百台远程服务器时，性能和安全就成了不可忽视的问题。掌握这些技巧可以避免脚本在生产中"慢到不可用"或"泄露敏感信息"。

```powershell
function Get-SecureAuditReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter()]
        [pscredential]$Credential,

        [Parameter()]
        [ValidateRange(1, 50)]
        [int]$ThrottleLimit = 10
    )

    # 构建安全的 CimSession 参数
    $cimParams = @{
        ErrorAction = 'Stop'
    }

    if ($Credential) {
        $cimParams.Credential = $Credential
    }

    # 并行处理远程主机，控制并发数
    $results = $ComputerName | ForEach-Object -ThrottleLimit $ThrottleLimit -Parallel {
        $computer = $_
        $params = $using:cimParams

        try {
            # 使用 CIM 替代 WMI，更安全且支持 WinRM
            $os = Get-CimInstance -ClassName Win32_OperatingSystem @params
            $patches = Get-CimInstance -ClassName Win32_QuickFixEngineering @params |
                Sort-Object InstalledOn -Descending -ErrorAction SilentlyContinue |
                Select-Object -First 5

            # 安全地提取凭据信息：只记录用户名，不记录密码
            [PSCustomObject]@{
                ComputerName    = $computer
                Status          = "Online"
                OSVersion       = $os.Caption
                LastBootTime    = $os.LastBootUpTime
                FreeSpaceGB     = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                RecentPatches   = $patches.HotFixID -join "; "
                AuditTime       = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        catch {
            [PSCustomObject]@{
                ComputerName = $computer
                Status       = "Error: $($_.Exception.Message)"
                OSVersion    = "N/A"
                LastBootTime = $null
                FreeSpaceGB  = "N/A"
                RecentPatches = "N/A"
                AuditTime    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }

    # 安全地输出结果，过滤敏感字段
    $results | Format-Table -AutoSize

    # 审计日志脱敏处理
    $logEntry = @{
        Action     = "SecurityAudit"
        Targets    = $ComputerName -join ","
        ResultCount = ($results | Where-Object Status -eq "Online").Count
        ExecutedBy = $env:USERNAME
        Timestamp  = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }

    # 注意：不要将 $Credential 或密码写入日志
    $logEntry | ConvertTo-Json -Compress
}

# 安全地传递凭据（交互式输入）
$cred = Get-Credential -Message "输入远程服务器管理凭据"
Get-SecureAuditReport -ComputerName "SRV01", "SRV02", "SRV03" -Credential $cred -ThrottleLimit 5
```

执行结果示例：

```
ComputerName Status  OSVersion                     LastBootTime         FreeSpaceGB RecentPatches         AuditTime
------------ ------  ---------                     ------------         ----------- -------------         ---------
SRV01        Online  Microsoft Windows Server 2022 2025-12-28 03:00:00       12.45 KB5044280;KB503... 2025-12-30 14:20:10
SRV02        Online  Microsoft Windows Server 2019 2025-12-29 06:30:00        8.72 KB5044277;KB503... 2025-12-30 14:20:12
SRV03        Error: 无法连接到远程服务器。         N/A                              N/A N/A                    2025-12-30 14:20:15

{"Action":"SecurityAudit","Targets":"SRV01,SRV02,SRV03","ResultCount":2,"ExecutedBy":"admin","Timestamp":"2025-12-30T14:20:15Z"}
```

这个函数使用了 `ForEach-Object -Parallel` 实现受控并发，用 CIM 替代已弃用的 WMI 协议，通过 `PSCredential` 对象安全传递凭据而非明文密码，审计日志中严格排除敏感字段。这些都是生产环境中必须考虑的安全和性能要点。

## 注意事项

1. **始终使用 approved verbs**：用 `Get-Verb` 查看合法动词列表，避免自定义动词导致命名不一致。如果不确定用什么动词，参考类似功能的内置 cmdlet。

2. **参数验证优于函数内 if 判断**：`[ValidateNotNullOrEmpty()]`、`[ValidateRange()]`、`[ValidateScript()]` 等属性在参数绑定时就生效，比函数体内的 `if` 检查更早报错，错误信息也更标准。

3. **永远不要在脚本中硬编码密码**：使用 `Get-Credential` 交互获取凭据，或从 Azure Key Vault、Windows Credential Manager 等安全存储读取。代码中的 `$Credential.Password` 是 `SecureString`，不能直接转为明文。

4. **用 `-ErrorAction Stop` 配合 try/catch**：全局设置 `$ErrorActionPreference = 'Stop'` 可能导致意想不到的中断，建议在特定命令上用 `-ErrorAction` 精确控制，然后在 try 块中捕获。

5. **大集合用 `@()` 包裹管道赋值**：`$items = @(Get-ChildItem ...)` 确保 `$items` 始终是数组，即使结果为空或只有一个元素。这样后续的 `.Count` 和 `foreach` 行为一致，不会踩类型陷阱。

6. **为函数写基于注释的帮助**：`.SYNOPSIS`、`.DESCRIPTION`、`.PARAMETER`、`.EXAMPLE` 四件套是最低要求。三个月后你自己也会感谢今天写了注释的那个函数，更不用说接手代码的同事了。
