---
layout: post
date: 2025-06-23 08:00:00
title: "PowerShell 技能连载 - 错误处理设计模式"
description: PowerTip of the Day - Error Handling Design Patterns in PowerShell
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
- patterns
---

_适用于 PowerShell 5.1 及以上版本_

"程序能工作"和"程序能可靠地工作"之间的差距，往往就在于错误处理。PowerShell 的错误处理机制比大多数脚本语言更丰富——有终止错误和非终止错误的区分、有 `$ErrorActionPreference` 全局设置、有 `try/catch/finally` 结构、有 `-ErrorVariable` 参数。理解这些机制并设计合理的错误处理模式，是编写生产级脚本的关键。

本文将系统讲解 PowerShell 的错误处理机制、常见设计模式，以及如何构建可靠的自动化脚本。

## 错误类型与控制

PowerShell 有两类错误：终止错误（Terminating Error，会停止执行）和非终止错误（Non-Terminating Error，默认只记录继续执行）：

```powershell
# 非终止错误：默认不会停止脚本
Get-Content "不存在的文件.txt" -ErrorAction SilentlyContinue
Write-Host "这行会执行"  # 即使上面报错

# 将非终止错误转为终止错误（可以被 try/catch 捕获）
try {
    Get-Content "不存在的文件.txt" -ErrorAction Stop
} catch {
    Write-Host "捕获到错误：$($_.Exception.Message)" -ForegroundColor Red
}

# 全局错误偏好
$ErrorActionPreference = 'Stop'  # 所有非终止错误都变成终止错误

# 使用 -ErrorVariable 收集错误
$erroredItems = @()
Get-ChildItem "C:\SomePath" -Recurse -ErrorVariable +erroredItems -ErrorAction SilentlyContinue

if ($erroredItems) {
    Write-Host "遇到 $($erroredItems.Count) 个错误：" -ForegroundColor Yellow
    $erroredItems | ForEach-Object { Write-Host "  $($_.Exception.Message)" }
}

# $error 自动变量（最近发生的错误列表）
$error | Select-Object -First 5 |
    ForEach-Object { Write-Host $_.Exception.Message }
```

执行结果示例：

```
捕获到错误：找不到路径"C:\不存在的文件.txt"的路径
遇到 3 个错误：
  拒绝访问路径 C:\Windows\System32\config
  找不到驱动器名为 "Z" 的驱动器
  拒绝访问路径 C:\Users\admin\NTUSER.DAT
```

## try/catch/finally 模式

```powershell
# 基础模式：捕获并记录
function Copy-FileSafe {
    param([string]$Source, [string]$Destination)

    try {
        Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop
        Write-Host "已复制：$Source => $Destination" -ForegroundColor Green
    } catch {
        Write-Host "复制失败：$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $true
}

# finally 模式：资源清理
function Invoke-DatabaseOperation {
    param([string]$ConnectionString)

    $connection = $null
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        Write-Host "数据库连接已建立" -ForegroundColor Green

        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT COUNT(*) FROM Users"
        $result = $command.ExecuteScalar()
        Write-Host "用户数量：$result"

    } catch {
        Write-Host "数据库操作失败：$($_.Exception.Message)" -ForegroundColor Red
        throw  # 重新抛出，让调用者处理
    } finally {
        # 无论成功失败，始终清理资源
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
            Write-Host "数据库连接已关闭" -ForegroundColor DarkGray
        }
    }
}

# 嵌套错误处理
function Deploy-Application {
    param([string]$AppName)

    try {
        Write-Host "开始部署：$AppName" -ForegroundColor Cyan

        try {
            Stop-Service $AppName -ErrorAction Stop
        } catch {
            Write-Host "服务未运行，跳过停止" -ForegroundColor Yellow
        }

        # 更新文件
        Copy-Item "C:\Releases\$AppName\*" "D:\Apps\$AppName\" -Recurse -Force

        Start-Service $AppName
        Write-Host "部署完成：$AppName" -ForegroundColor Green

    } catch {
        Write-Host "部署失败，回滚中..." -ForegroundColor Red
        # 回滚逻辑
        try {
            Start-Service $AppName -ErrorAction SilentlyContinue
        } catch {}
        throw "部署失败：$($_.Exception.Message)"
    }
}
```

执行结果示例：

```
已复制：C:\Data\file.txt => D:\Backup\file.txt

数据库连接已建立
用户数量：85234
数据库连接已关闭

开始部署：MyApp
服务未运行，跳过停止
部署完成：MyApp
```

## 重试模式

网络操作和外部 API 调用经常因临时故障失败，重试模式是必备的：

```powershell
function Invoke-WithRetry {
    <#
    .SYNOPSIS
    带指数退避重试的执行包装器
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxRetries = 3,
        [int]$BaseDelaySeconds = 2,
        [double]$BackoffMultiplier = 2.0,
        [string]$Description = "操作"
    )

    $attempt = 0
    $lastError = $null

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            $result = & $ScriptBlock
            if ($attempt -gt 1) {
                Write-Host "$Description 在第 $attempt 次尝试成功" -ForegroundColor Green
            }
            return $result
        } catch {
            $lastError = $_

            if ($attempt -ge $MaxRetries) {
                Write-Host "$Description 失败，已重试 $MaxRetries 次" -ForegroundColor Red
                throw
            }

            $delay = $BaseDelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt - 1)
            Write-Host "$description 第 $attempt 次失败，${delay}秒后重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delay
        }
    }
}

# 使用重试模式调用 API
$result = Invoke-WithRetry -Description "调用 GitHub API" -MaxRetries 3 -ScriptBlock {
    Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -ErrorAction Stop
}

# 重试文件操作
Invoke-WithRetry -Description "复制大文件" -ScriptBlock {
    Copy-Item "\\server\share\large-file.zip" "C:\Downloads\" -Force -ErrorAction Stop
}
```

执行结果示例：

```
调用 GitHub API 第 1 次失败，2秒后重试...
调用 GitHub API 在第 2 次尝试成功
```

## 错误日志记录

```powershell
function Write-ErrorLog {
    <#
    .SYNOPSIS
    将错误信息写入日志文件
    #>
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [string]$LogPath = "C:\Logs\errors.log",
        [string]$Context
    )

    $entry = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Context   = $Context
        Message   = $ErrorRecord.Exception.Message
        Category  = $ErrorRecord.CategoryInfo.Category
        Target    = $ErrorRecord.TargetObject
        Script    = $ErrorRecord.InvocationInfo.ScriptName
        Line      = $ErrorRecord.InvocationInfo.ScriptLineNumber
    }

    $entry | Export-Csv -Path $LogPath -Append -NoTypeInformation -Encoding UTF8
}

# 使用示例
try {
    Get-Content "不存在的文件.txt" -ErrorAction Stop
} catch {
    Write-ErrorLog -ErrorRecord $_ -Context "读取配置文件"
    Write-Host "错误已记录到日志" -ForegroundColor Yellow
}
```

执行结果示例：

```
错误已记录到日志
```

## 注意事项

1. **区分错误类型**：`-ErrorAction Stop` 将非终止错误转为终止错误，这是让 `try/catch` 生效的关键
2. **不要吞掉错误**：空 catch 块 `{}` 会隐藏所有错误信息，至少记录日志
3. **finally 始终执行**：无论是否发生异常、是否有 return 语句，finally 块都会执行
4. **$ErrorView**：PowerShell 7 中 `$ErrorView = 'ConciseView'` 提供更简洁的错误输出
5. **错误记录对象**：`$_` 在 catch 块中是 `ErrorRecord` 对象，包含 `Exception`、`CategoryInfo`、`InvocationInfo` 等详细信息
6. **throw vs Write-Error**：`throw` 创建终止错误，`Write-Error` 创建非终止错误。在函数中选择合适的错误类型
