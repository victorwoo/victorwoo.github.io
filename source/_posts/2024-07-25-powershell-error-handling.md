---
layout: post
date: 2024-07-25 08:00:00
title: "PowerShell错误处理核心机制"
description: "掌握异常捕获与调试的核心技巧"
categories:
- powershell
- basic
---

## 异常捕获原理
```powershell
# 基础try/catch结构
try {
    1/0
}
catch {
    Write-Host "捕获异常: $_"
}
finally {
    Write-Host "清理操作"
}
```

## 错误类型对比
| 错误类型       | 触发条件       | 处理方式  |
|----------------|----------------|-----------|
| 终止错误       | 严重运行时错误 | try/catch |
| 非终止错误     | 可继续执行错误 | -ErrorAction |
| 语法错误       | 脚本解析错误   | 预检查    |

## 典型应用场景
1. 使用$Error自动变量追溯错误历史
2. 通过-ErrorVariable捕获特定命令错误
3. 设置$ErrorActionPreference控制全局行为
4. 自定义错误信息模板

## 调试技巧
```powershell
# 启用详细调试模式
$DebugPreference = 'Continue'
Write-Debug "调试信息"

# 设置错误断点
Set-PSBreakpoint -Command Write-Error
```