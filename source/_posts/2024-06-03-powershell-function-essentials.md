---
layout: post
date: 2024-06-03 08:00:00
title: "PowerShell函数开发实战"
description: "从基础语法到高级参数处理"
categories:
- powershell
- scripting
tags:
- function
- parameters
---

## 基础函数结构
```powershell
function Get-ServerStatus {
    param(
        [string]$ComputerName
    )
    Test-Connection $ComputerName -Count 1 -Quiet
}
```

## 高级参数验证
```powershell
function New-UserAccount {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[a-zA-Z]{3,8}$')]
        [string]$UserName,
        
        [ValidateSet('Standard','Admin')]
        [string]$Role = 'Standard'
    )
    # 创建逻辑
}
```

## 管道输入处理
```powershell
function Process-FileData {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [System.IO.FileInfo]$File
    )
    process {
        [PSCustomObject]@{
            Name = $File.Name
            Size = $File.Length
            Hash = (Get-FileHash $File.FullName).Hash
        }
    }
}
```

## 函数最佳实践
1. 使用注释式帮助系统
2. 实现ShouldProcess确认机制
3. 合理设置输出类型
4. 保持函数功能单一化