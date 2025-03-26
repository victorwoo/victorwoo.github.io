---
layout: post
date: 2024-11-11 08:00:00
title: "PowerShell错误处理完全指南"
description: "掌握异常捕获与调试的核心技巧"
categories:
- powershell
- basic
---

## 错误类型解析
```powershell
# 终止错误示例
1/0

# 非终止错误示例
Write-Error "操作警告"
```

## 异常捕获实战
```powershell
try {
    Get-Content -Path "不存在文件.txt" -ErrorAction Stop
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Host "文件未找到：$($_.Exception.Message)"
}
finally {
    Write-Host "清理完成"
}
```

## 调试技巧
1. 使用$Error自动变量追溯错误堆栈
2. 通过-ErrorVariable参数捕获错误信息
3. 设置$ErrorActionPreference控制全局行为
4. 使用Set-PSBreakpoint设置调试断点

## 最佳实践
```powershell
# 自定义错误信息模板
throw [System.Management.Automation.ErrorRecord]::new(
    [Exception]::new("业务逻辑异常"),
    "ErrorID001",
    [System.Management.Automation.ErrorCategory]::InvalidOperation,
    $null
)