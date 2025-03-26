---
layout: post
date: 2024-08-19 08:00:00
title: "PowerShell变量作用域深度解析"
description: "掌握全局/脚本/局部作用域的运作机制"
categories:
- powershell
- basic
---

## 作用域层级解析
```powershell
# 全局作用域示例
$global:config = 'Server1'

function Show-Config {
    # 局部作用域
    $local:connection = 'Active'
    "$global:config - $local:connection"
}
Show-Config
```

## 作用域修饰符实战
```powershell
# 跨作用域访问
function Set-Cache {
    $script:cache = @{}
    $cache.Add('timestamp', (Get-Date))
}

Set-Cache
$script:cache.Values
```

## 注意事项
1. 使用$private:限制变量可见范围
2. 通过Get-Variable -Scope查看不同作用域变量
3. 避免在函数内意外修改全局变量
4. 嵌套函数中的变量继承规则