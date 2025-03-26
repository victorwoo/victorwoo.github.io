---
layout: post
date: 2024-05-08 08:00:00
title: "PowerShell函数高级应用指南"
description: "掌握参数校验与管道集成的核心技巧"
categories:
- powershell
- basic
---

## 函数参数校验
```powershell
function Get-UserInfo {
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z]+$')]
        [string]$UserName,
        
        [ValidateRange(18,120)]
        [int]$Age
    )
    "用户: $UserName 年龄: $Age"
}
```

## 管道集成实战
```powershell
function Process-Files {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]$Files
    )
    process {
        $_.FullName | ForEach-Object {
            "处理文件: $_"
        }
    }
}
```

## 性能优化建议
1. 避免在循环内创建函数
2. 使用begin/process/end块处理流数据
3. 合理使用参数集(ParameterSet)
4. 采用类型约束提升执行效率