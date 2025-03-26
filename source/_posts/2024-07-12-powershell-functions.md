---
layout: post
date: 2024-07-12 08:00:00
title: "PowerShell 技能连载 - 高级函数开发技巧"
description: "掌握PowerShell函数参数验证与管道输入处理"
categories:
- powershell
- scripting
tags:
- powershell
- functions
- automation
---

### 参数验证体系
```powershell
function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidatePattern('^[a-zA-Z]')]
        [string[]]$ComputerName,
        
        [ValidateSet('CPU','Memory','Disk')]
        [string]$Category = 'CPU'
    )
    begin { 
        $results = @()
    }
    process {
        foreach ($computer in $ComputerName) {
            $data = [PSCustomObject]@{
                Computer = $computer
                Status = 'Online'
                $Category = (Get-CimInstance -ClassName Win32_$Category)
            }
            $results += $data
        }
    }
    end {
        $results
    }
}
```

### 管道输入优化
```powershell
# 支持三种输入方式
'Server01','Server02' | Get-SystemInfo -Category Memory

Get-Content servers.txt | Get-SystemInfo

Get-SystemInfo -ComputerName (Import-Csv -Path datacenter.csv).Name
```

最佳实践：
- 使用begin/process/end块处理流水线
- 通过ValidatePattern限制输入格式
- 利用ValueFromPipeline属性支持管道
- 添加帮助注释增强可维护性