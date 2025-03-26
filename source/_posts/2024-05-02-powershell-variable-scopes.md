---
layout: post
date: 2024-05-02 08:00:00
title: "PowerShell变量作用域深度解析"
description: "掌握局部、全局与脚本作用域的应用场景"
categories:
- powershell
- scripting
tags:
- variable
- scope
---

## 基础作用域类型
```powershell
$global:counter = 10  # 全局作用域

function Show-Count {
    $script:total = 20  # 脚本作用域
    $local:temp = 5    # 局部作用域
    $global:counter + $script:total + $local:temp
}
```

## 作用域穿透技巧
```powershell
# 使用Get-Variable跨作用域访问
Get-Variable counter -Scope Global

# 使用Set-Variable修改父作用域
function Update-Count {
    Set-Variable -Name counter -Value 15 -Scope 1
}
```

## 最佳实践
1. 优先使用参数传递替代跨作用域访问
2. 谨慎使用global作用域
3. 在模块中使用$script作用域保持状态
4. 使用private修饰符保护关键变量