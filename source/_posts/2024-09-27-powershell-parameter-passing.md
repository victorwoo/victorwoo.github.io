---
layout: post
date: 2024-09-27 08:00:00
title: "PowerShell参数传递机制详解"
description: "掌握位置参数、命名参数与管道输入的三种传递方式"
categories:
- powershell
- basic
---

## 参数传递基础原理
```powershell
# 位置参数示例
function Get-FullName {
    param($FirstName, $LastName)
    "$FirstName $LastName"
}
Get-FullName '张' '三'

# 命名参数示例
Get-FullName -LastName '李' -FirstName '四'
```

## 管道参数绑定
```powershell
1..5 | ForEach-Object { 
    param([int]$num)
    $num * 2 
}
```

## 实用技巧
1. 使用[Parameter(Mandatory)]标记必选参数
2. 通过ValueFromPipeline实现流式处理
3. 验证集ValidateSet限制参数取值范围
4. 类型转换失败时的错误处理策略