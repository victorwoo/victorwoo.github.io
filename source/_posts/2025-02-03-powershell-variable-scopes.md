---
layout: post
date: 2025-02-03 08:00:00
title: "PowerShell 变量作用域深度解析"
description: "掌握脚本中变量可见性的核心机制"
categories:
- powershell
- scripting
tags:
- variables
- scope
---

### 作用域修饰符实战
```powershell
# 全局作用域演示
$global:config = 'Server1'
function Show-Config {
    Write-Host "全局配置: $global:config"
}

# 本地作用域示例
function Set-LocalValue {
    $local:temp = '临时数据'
    Write-Host "函数内部值: $temp"
}

# 脚本作用域应用
$script:counter = 0
function Increment-Counter {
    $script:counter++
    Write-Host "当前计数: $script:counter"
}

# 跨作用域调用演示
Show-Config
Set-LocalValue
Increment-Counter
Increment-Counter
```

### 作用域穿透技巧
```powershell
# 使用Get-Variable跨作用域访问
function Get-RemoteValue {
    param($varName)
    Get-Variable -Name $varName -Scope 1 -ValueOnly
}

$outerVar = '外层数据'
function Show-Nested {
    $innerVar = '内部数据'
    Write-Host "穿透获取: $(Get-RemoteValue 'outerVar')"
}
```

### 最佳实践
1. 优先使用local修饰符保护临时变量
2. 避免在函数内直接修改global作用域
3. 使用script作用域维护模块级状态
4. 通过$PSDefaultParameterValues设置默认作用域