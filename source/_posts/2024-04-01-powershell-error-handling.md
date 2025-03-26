---
layout: post
date: 2024-04-01 08:00:00
title: "PowerShell 技能连载 - 错误处理机制"
description: PowerTip of the Day - PowerShell Error Handling
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 异常处理基础结构

```powershell
try {
    Get-Content -Path '不存在的文件.txt' -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Warning "文件未找到: $($_.Exception.Message)"
}
catch {
    Write-Error "未知错误: $_"
}
finally {
    Write-Output "清理操作完成"
}
```

## 错误类型识别
1. **终止错误**：必须使用-ErrorAction Stop
2. **非终止错误**：通过$Error自动变量捕获

## 高级处理技巧
```powershell
# 自定义错误记录
$ErrorActionPreference = 'Continue'
$ErrorView = 'NormalView'

function Invoke-SafeOperation {
    [CmdletBinding()]
    param([scriptblock]$ScriptBlock)
    
    try {
        & $ScriptBlock
    }
    catch {
        [PSCustomObject]@{
            Timestamp = Get-Date
            ErrorType = $_.Exception.GetType().Name
            Message = $_.Exception.Message
            ScriptLine = $_.InvocationInfo.ScriptLineNumber
        } | Export-Csv -Path 'errors.log' -Append
    }
}
```

## 最佳实践
1. 区分可恢复与不可恢复错误
2. 使用ErrorRecord对象获取完整信息
3. 通过$ErrorActionPreference控制默认行为
4. 定期清理$Error自动变量

```powershell
# 错误信息增强处理
$Error[0] | Select-Object *
$Error[0].InvocationInfo | Format-List *
$Error[0].Exception | Format-List *
```