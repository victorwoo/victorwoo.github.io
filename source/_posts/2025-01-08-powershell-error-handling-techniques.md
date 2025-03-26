---
layout: post
date: 2025-01-08 08:00:00
title: "PowerShell 技能连载 - 高级错误处理技术"
description: PowerTip of the Day - PowerShell Advanced Error Handling Techniques
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在PowerShell脚本开发中，有效的错误处理是确保脚本健壮性和可靠性的关键。本文将介绍一系列高级错误处理技术，帮助您编写更专业的PowerShell脚本。

## 基础错误处理

首先，让我们回顾PowerShell中的基本错误处理机制：

```powershell
# 使用try/catch/finally块处理错误
try {
    # 尝试执行的代码
    Get-Content -Path "C:\NonExistentFile.txt" -ErrorAction Stop
}
catch {
    # 错误处理代码
    Write-Host "发生错误: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # 无论是否发生错误都会执行的代码
    Write-Host "操作完成" -ForegroundColor Yellow
}
```

## 使用$ErrorActionPreference

PowerShell的`$ErrorActionPreference`变量控制脚本遇到错误时的默认行为：

```powershell
# 设置全局错误处理行为
$ErrorActionPreference = 'Stop'  # 遇到错误时停止执行
# 其他选项: Continue（默认），SilentlyContinue，Ignore，Inquire

# 代码块中临时改变错误处理行为
$originalEAP = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    # 尝试执行的代码，错误会被忽略
    Get-Process -Name "NonExistentProcess"
}
finally {
    # 恢复原始错误处理行为
    $ErrorActionPreference = $originalEAP
}
```

## 创建自定义错误记录器

下面是一个自定义错误记录函数，可帮助您以统一格式记录错误：

```powershell
function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter()]
        [string]$LogPath = "C:\Logs\PowerShell_Errors.log",
        
        [Parameter()]
        [switch]$PassThru
    )
    
    # 确保日志目录存在
    $logDir = Split-Path -Path $LogPath -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # 格式化错误信息
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $errorMessage = $ErrorRecord.Exception.Message
    $errorLine = $ErrorRecord.InvocationInfo.Line.Trim()
    $errorPosition = $ErrorRecord.InvocationInfo.PositionMessage
    $errorCategory = $ErrorRecord.CategoryInfo.Category
    $errorType = $ErrorRecord.Exception.GetType().FullName
    
    # 构建详细错误信息
    $logEntry = @"
[${timestamp}] 
ERROR TYPE: $errorType
CATEGORY: $errorCategory
MESSAGE: $errorMessage
LINE: $errorLine
POSITION: $errorPosition
STACK TRACE: 
$($ErrorRecord.ScriptStackTrace)
====================
"@
    
    # 记录到文件
    Add-Content -Path $LogPath -Value $logEntry
    
    # 输出给调用者
    if ($PassThru) {
        return $ErrorRecord
    }
}

# 使用示例
try {
    # 故意触发错误
    1/0
}
catch {
    # 记录错误
    Write-ErrorLog -ErrorRecord $_
    # 输出友好的错误消息
    Write-Host "发生计算错误，详情已记录到日志文件" -ForegroundColor Red
}
```

## 使用trap语句进行错误处理

`trap`语句是另一种捕获和处理错误的机制，特别适用于需要统一处理整个脚本中错误的情况：

```powershell
# 在脚本开始处设置trap
trap {
    Write-Host "捕获到错误: $($_.Exception.Message)" -ForegroundColor Red
    # 继续执行（如果可能）
    continue
    
    # 或者终止当前执行范围并移至调用者
    # break
}

# 现在脚本中的任何未经处理的错误都会被trap捕获
Get-Process -Name "NonExistentProcess"
Write-Host "这行仍会执行，因为我们在trap中使用了continue"
```

## 不同作用域的trap

您可以在不同的作用域中设置多个trap来处理不同类型的错误：

```powershell
# 默认trap（捕获所有错误）
trap {
    Write-Host "默认trap: $($_.Exception.Message)" -ForegroundColor Red
    continue
}

# 特定异常类型的trap
trap [System.DivideByZeroException] {
    Write-Host "除零错误trap: $($_.Exception.Message)" -ForegroundColor Yellow
    continue
}

# 特定命令产生的错误
trap [System.Management.Automation.CommandNotFoundException] {
    Write-Host "命令未找到trap: $($_.Exception.Message)" -ForegroundColor Cyan
    continue
}

# 测试不同类型的错误
1/0  # 触发除零错误
Get-NonExistentCommand  # 触发命令未找到错误
[System.IO.File]::ReadAllText("C:\NonExistentFile.txt")  # 触发文件未找到错误
```

## 创建高级错误处理函数

下面是一个更全面的错误处理函数，它结合了记录、通知和重试功能：

```powershell
function Invoke-WithErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [string]$ErrorMessage = "执行脚本块时发生错误",
        
        [Parameter()]
        [string]$LogPath,
        
        [Parameter()]
        [switch]$SuppressOutput,
        
        [Parameter()]
        [int]$RetryCount = 0,
        
        [Parameter()]
        [int]$RetryDelaySeconds = 5,
        
        [Parameter()]
        [scriptblock]$OnErrorAction,
        
        [Parameter()]
        [scriptblock]$FinallyAction
    )
    
    $attempt = 0
    $maxAttempts = $RetryCount + 1  # 初始尝试 + 重试次数
    $success = $false
    $result = $null
    
    do {
        $attempt++
        try {
            Write-Verbose "执行脚本块 (尝试 $attempt/$maxAttempts)"
            
            # 执行脚本块
            $result = & $ScriptBlock
            $success = $true
            
            # 成功完成，退出循环
            break
        }
        catch {
            $currentError = $_
            
            # 构建详细错误信息
            $detailedError = @{
                Message = $currentError.Exception.Message
                Type = $currentError.Exception.GetType().FullName
                ScriptStackTrace = $currentError.ScriptStackTrace
                PositionMessage = $currentError.InvocationInfo.PositionMessage
                Line = $currentError.InvocationInfo.Line.Trim()
                Time = Get-Date
                Attempt = $attempt
            }
            
            # 记录错误
            if ($LogPath) {
                $logEntry = "[$($detailedError.Time.ToString('yyyy-MM-dd HH:mm:ss'))] 尝试 $($detailedError.Attempt)/$maxAttempts`n"
                $logEntry += "错误: $($detailedError.Message)`n"
                $logEntry += "类型: $($detailedError.Type)`n"
                $logEntry += "位置: $($detailedError.PositionMessage)`n"
                $logEntry += "堆栈跟踪: $($detailedError.ScriptStackTrace)`n"
                $logEntry += "====================`n"
                
                # 确保日志目录存在
                $logDir = Split-Path -Path $LogPath -Parent
                if (-not (Test-Path -Path $logDir)) {
                    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
                }
                
                Add-Content -Path $LogPath -Value $logEntry
            }
            
            # 执行自定义错误处理动作
            if ($OnErrorAction) {
                & $OnErrorAction -ErrorInfo $detailedError
            }
            
            # 检查是否需要重试
            if ($attempt -lt $maxAttempts) {
                Write-Verbose "将在 $RetryDelaySeconds 秒后重试..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                # 已达到最大尝试次数，重新抛出错误
                if (-not $SuppressOutput) {
                    Write-Error "$ErrorMessage`n$($detailedError.Message)"
                }
            }
        }
        finally {
            # 执行finally代码块
            if ($FinallyAction) {
                & $FinallyAction
            }
        }
    } while ($attempt -lt $maxAttempts)
    
    if ($success) {
        return $result
    }
}

# 使用示例
$result = Invoke-WithErrorHandling -ScriptBlock {
    # 模拟一个可能失败的操作
    if ((Get-Random -Minimum 1 -Maximum 4) -eq 1) {
        # 操作成功
        return "操作成功"
    }
    else {
        # 操作失败
        throw "随机故障发生"
    }
} -ErrorMessage "执行关键操作时失败" -RetryCount 3 -RetryDelaySeconds 2 -LogPath "C:\Logs\Retry.log" -Verbose -OnErrorAction {
    param($ErrorInfo)
    Write-Host "发生错误，尝试 $($ErrorInfo.Attempt)，错误消息: $($ErrorInfo.Message)" -ForegroundColor Yellow
}

if ($result) {
    Write-Host "最终结果: $result" -ForegroundColor Green
}
```

## 在函数中处理管道输入错误

当编写接受管道输入的函数时，错误处理需要特别注意：

```powershell
function Process-Items {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [object]$InputObject
    )
    
    begin {
        Write-Verbose "开始处理项目..."
        $errorCount = 0
        $successCount = 0
    }
    
    process {
        try {
            # 处理每个项目
            Write-Verbose "正在处理: $InputObject"
            
            # 模拟处理
            if ($InputObject -eq "bad") {
                throw "发现坏项目!"
            }
            
            # 处理成功
            $successCount++
            Write-Host "成功处理: $InputObject" -ForegroundColor Green
        }
        catch {
            $errorCount++
            Write-Host "处理项目 '$InputObject' 时出错: $($_.Exception.Message)" -ForegroundColor Red
            
            # 可以选择如何处理单个项目的错误:
            # 1. 继续处理下一个项目 (如本例)
            # 2. 通过 throw 停止所有处理
            # 3. 将错误写入错误流但继续处理
            #    $PSCmdlet.WriteError($_)
        }
    }
    
    end {
        Write-Verbose "处理完成。成功: $successCount, 失败: $errorCount"
        
        # 返回摘要对象
        [PSCustomObject]@{
            SuccessCount = $successCount
            ErrorCount = $errorCount
            TotalCount = $successCount + $errorCount
        }
    }
}

# 使用示例
"item1", "bad", "item3" | Process-Items -Verbose
```

## 错误过滤器和自定义错误类

您可以创建自定义错误类型和错误过滤器来更好地组织错误处理：

```powershell
# 定义自定义错误类
class CustomValidationError : System.Exception {
    [string]$Reason
    [object]$Value
    
    CustomValidationError([string]$message, [string]$reason, [object]$value) : base($message) {
        $this.Reason = $reason
        $this.Value = $value
    }
}

# 验证函数
function Test-PositiveNumber {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    if (-not [double]::TryParse($Value, [ref]$null)) {
        throw [CustomValidationError]::new(
            "值 '$Value' 不是有效的数字",
            "InvalidFormat",
            $Value
        )
    }
    
    if ([double]$Value -le 0) {
        throw [CustomValidationError]::new(
            "值 '$Value' 不是正数",
            "NotPositive",
            $Value
        )
    }
    
    return $true
}

# 使用示例
try {
    $number = "-5"
    Test-PositiveNumber -Value $number
}
catch [CustomValidationError] {
    # 处理自定义验证错误
    $error = $_
    Write-Host "验证错误: $($error.Exception.Message)" -ForegroundColor Red
    Write-Host "原因: $($error.Exception.Reason)" -ForegroundColor Yellow
    Write-Host "提供的值: $($error.Exception.Value)" -ForegroundColor Yellow
}
catch {
    # 处理其他错误
    Write-Host "其他错误: $($_.Exception.Message)" -ForegroundColor Red
}
```

## 创建一个完整的错误处理框架

最后，让我们创建一个全面的错误处理框架，可以在多个脚本中重用：

```powershell
# ErrorHandling.psm1
function Initialize-ErrorHandling {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath = "$env:TEMP\PowerShell_Errors.log",
        
        [Parameter()]
        [ValidateSet('Continue', 'Stop', 'SilentlyContinue', 'Inquire', 'Ignore')]
        [string]$DefaultAction = 'Continue',
        
        [Parameter()]
        [switch]$EnableGlobalErrorLogging,
        
        [Parameter()]
        [switch]$EnableGlobalErrorTrapping,
        
        [Parameter()]
        [scriptblock]$GlobalErrorAction
    )
    
    # 设置默认错误操作
    $script:OriginalErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = $DefaultAction
    
    # 确保日志目录存在
    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        $logDir = Split-Path -Path $LogPath -Parent
        if (-not (Test-Path -Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        $script:ErrorLogPath = $LogPath
    }
    
    # 设置全局错误日志记录
    if ($EnableGlobalErrorLogging) {
        # 覆盖$Error.Clear()方法以记录错误
        $ExecutionContext.SessionState.PSVariable.Set('ErrorClearOriginal', ${function:Clear-Error})
        
        function global:Clear-Error {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            foreach ($err in $global:Error) {
                $errorEntry = "[$timestamp] ERROR: $($err.Exception.Message)`nCATEGORY: $($err.CategoryInfo.Category)`nFULL: $($err | Out-String)"
                Add-Content -Path $script:ErrorLogPath -Value $errorEntry
            }
            & $function:ErrorClearOriginal
        }
    }
    
    # 设置全局错误捕获
    if ($EnableGlobalErrorTrapping) {
        trap {
            # 记录错误
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $errorEntry = @"
[$timestamp] TRAPPED ERROR
MESSAGE: $($_.Exception.Message)
TYPE: $($_.Exception.GetType().FullName)
SCRIPT: $($_.InvocationInfo.ScriptName)
LINE NUMBER: $($_.InvocationInfo.ScriptLineNumber)
LINE: $($_.InvocationInfo.Line.Trim())
POSITION: $($_.InvocationInfo.PositionMessage)
STACK TRACE:
$($_.ScriptStackTrace)
====================
"@
            Add-Content -Path $script:ErrorLogPath -Value $errorEntry
            
            # 执行自定义错误处理
            if ($GlobalErrorAction) {
                & $GlobalErrorAction -ErrorRecord $_
            }
            
            # 继续执行
            continue
        }
    }
    
    Write-Verbose "已初始化错误处理框架 (日志路径: $script:ErrorLogPath)"
}

function Reset-ErrorHandling {
    [CmdletBinding()]
    param()
    
    # 恢复原始错误操作首选项
    if ($script:OriginalErrorActionPreference) {
        $ErrorActionPreference = $script:OriginalErrorActionPreference
    }
    
    # 移除全局trap（不可能直接实现，需要重新启动会话）
    
    Write-Verbose "已重置错误处理配置"
}

function Write-DetailedError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [Parameter()]
        [string]$LogPath = $script:ErrorLogPath,
        
        [Parameter()]
        [switch]$PassThru,
        
        [Parameter()]
        [ValidateSet('Verbose', 'Warning', 'Error', 'Host', 'None')]
        [string]$OutputType = 'Host'
    )
    
    # 格式化详细错误信息
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedError = @"
[$timestamp] ERROR DETAILS
MESSAGE: $($ErrorRecord.Exception.Message)
TYPE: $($ErrorRecord.Exception.GetType().FullName)
SCRIPT: $($ErrorRecord.InvocationInfo.ScriptName)
LINE NUMBER: $($ErrorRecord.InvocationInfo.ScriptLineNumber)
LINE: $($ErrorRecord.InvocationInfo.Line.Trim())
POSITION: $($ErrorRecord.InvocationInfo.PositionMessage)
STACK TRACE:
$($ErrorRecord.ScriptStackTrace)
CATEGORY: $($ErrorRecord.CategoryInfo.Category)
REASON: $($ErrorRecord.CategoryInfo.Reason)
TARGET: $($ErrorRecord.CategoryInfo.TargetName)
FULL ERROR:
$($ErrorRecord | Out-String)
====================
"@
    
    # 记录到文件
    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        Add-Content -Path $LogPath -Value $formattedError
    }
    
    # 输出错误
    switch ($OutputType) {
        'Verbose' { Write-Verbose $formattedError }
        'Warning' { Write-Warning $ErrorRecord.Exception.Message }
        'Error' { Write-Error $ErrorRecord.Exception.Message }
        'Host' { 
            Write-Host "ERROR: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
            Write-Host "DETAILS: Type=$($ErrorRecord.Exception.GetType().Name), Script=$($ErrorRecord.InvocationInfo.ScriptName)" -ForegroundColor DarkRed
        }
        'None' { }
    }
    
    # 返回错误
    if ($PassThru) {
        return $ErrorRecord
    }
}

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [int]$RetryIntervalSeconds = 5,
        
        [Parameter()]
        [scriptblock]$RetryCondition = { $true },
        
        [Parameter()]
        [string]$LogPath = $script:ErrorLogPath,
        
        [Parameter()]
        [scriptblock]$OnRetry
    )
    
    $attempt = 0
    $maxAttempts = $RetryCount + 1  # 初始尝试 + 重试次数
    
    do {
        $attempt++
        $lastError = $null
        
        try {
            Write-Verbose "执行代码块 (尝试 $attempt/$maxAttempts)"
            # 执行脚本块并返回结果
            return & $ScriptBlock
        }
        catch {
            $lastError = $_
            
            # 记录错误
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $retryLog = @"
[$timestamp] RETRY ATTEMPT $attempt/$maxAttempts
ERROR: $($lastError.Exception.Message)
TYPE: $($lastError.Exception.GetType().FullName)
====================
"@
            if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
                Add-Content -Path $LogPath -Value $retryLog
            }
            
            # 执行OnRetry动作
            if ($OnRetry) {
                & $OnRetry -ErrorRecord $lastError -Attempt $attempt -MaxAttempts $maxAttempts
            }
            
            # 检查是否满足重试条件
            $shouldRetry = & $RetryCondition -ErrorRecord $lastError
            
            if ($shouldRetry -and $attempt -lt $maxAttempts) {
                Write-Verbose "在 $RetryIntervalSeconds 秒后重试..."
                Start-Sleep -Seconds $RetryIntervalSeconds
            }
            else {
                # 已达到最大重试次数或不满足重试条件
                throw $lastError
            }
        }
    } while ($attempt -lt $maxAttempts)
}

# 导出模块函数
Export-ModuleMember -Function Initialize-ErrorHandling, Reset-ErrorHandling, Write-DetailedError, Invoke-WithRetry
```

使用错误处理框架的示例：

```powershell
# 导入错误处理模块
Import-Module ErrorHandling.psm1

# 初始化错误处理
Initialize-ErrorHandling -LogPath "C:\Logs\MyScript.log" -DefaultAction "Stop" -EnableGlobalErrorLogging -Verbose

try {
    # 使用重试机制执行不稳定操作
    $result = Invoke-WithRetry -ScriptBlock {
        # 模拟不稳定操作
        if ((Get-Random -Minimum 1 -Maximum 5) -lt 3) {
            throw "临时错误，可重试"
        }
        return "操作成功"
    } -RetryCount 5 -RetryIntervalSeconds 2 -OnRetry {
        param($ErrorRecord, $Attempt, $MaxAttempts)
        Write-Host "重试 $Attempt/$MaxAttempts..." -ForegroundColor Yellow
    } -Verbose
    
    Write-Host "最终结果: $result" -ForegroundColor Green
}
catch {
    # 详细记录错误
    Write-DetailedError -ErrorRecord $_ -OutputType "Host"
    
    # 执行清理操作
    Write-Host "执行错误后清理..." -ForegroundColor Cyan
}
finally {
    # 重置错误处理设置
    Reset-ErrorHandling
}
```

## 最佳实践总结

1. **预见错误**：识别脚本中可能发生错误的区域，并相应地进行处理。
2. **使用try/catch/finally**：对于可能失败的关键操作，始终使用try/catch块。
3. **使用-ErrorAction参数**：在单个命令级别控制错误行为。
4. **记录错误**：将错误详细信息记录到日志文件，以便后续分析。
5. **实现重试逻辑**：对于网络或其他间歇性操作，实现自动重试。
6. **提供有意义的错误消息**：确保错误消息清晰、具有描述性，并包含足够的上下文信息。
7. **使用自定义错误类型**：对于复杂应用程序，考虑创建自定义错误类型。
8. **测试错误处理**：专门测试错误路径，确保它们按预期工作。

通过实施这些高级错误处理技术，您的PowerShell脚本将更加健壮，更易于调试和维护。良好的错误处理不仅能提高脚本质量，还能降低运营风险，特别是在自动化关键业务流程时。 