---
layout: post
date: 2024-09-24 08:00:00
title: "PowerShell管道过滤器实战指南"
description: "掌握数据流处理的核心机制"
categories:
- powershell
- basic
---

## 管道过滤器原理
```powershell
# 基础过滤示例
Get-Process | Where-Object {$_.CPU -gt 100} | Select-Object Name, Id

# 自定义过滤函数
function Filter-LargeFiles {
    param([int]$SizeMB=50)
    Process {
        if ($_.Length -gt $SizeMB*1MB) {
            $_
        }
    }
}

Get-ChildItem -Recurse | Filter-LargeFiles -SizeMB 100
```

## 性能优化要点
1. 尽量在管道前端过滤
2. 避免在过滤器中执行耗时操作
3. 合理使用流式处理与缓存机制

## 典型应用场景
```powershell
# 实时监控进程创建
Get-WmiObject -Query "SELECT * FROM __InstanceCreationEvent WITHIN 2 WHERE TargetInstance ISA 'Win32_Process'" | 
ForEach-Object {
    $process = $_.TargetInstance
    Write-Host "新进程: $($process.Name) (PID: $($process.ProcessId))"
}
```

## 调试技巧
```powershell
# 查看中间结果
Get-Service | Tee-Object -Variable temp | Where-Object Status -eq 'Running'
$temp | Format-Table -AutoSize
```