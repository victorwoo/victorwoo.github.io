---
layout: post
date: 2024-11-07 08:00:00
title: "PowerShell数组操作完全指南"
description: "掌握数据结构的基础操作方法"
categories:
- powershell
- basic
---

## 数组创建与访问
```powershell
# 基础数组创建
$numbers = 1,2,3,4,5
$letters = @('a','b','c')

# 多维数组示例
$matrix = @(
    @(1,2,3),
    @(4,5,6)
)
Write-Host $matrix[1][0] # 输出4
```

## 常用操作方法
| 方法        | 描述                  | 示例               |
|-------------|-----------------------|--------------------|
| +=          | 追加元素              | $numbers += 6      |
| .Count      | 获取元素数量          | $letters.Count     |
| -join       | 连接为字符串          | $numbers -join ',' |
| .Where({})  | 条件筛选              | $numbers.Where{$_ -gt 3} |

## 性能优化建议
```powershell
# 预分配大数组
$bigArray = New-Object object[] 10000

# 使用ArrayList动态操作
$list = [System.Collections.ArrayList]::new()
$list.AddRange(1..1000)
```

## 典型应用场景
```powershell
# CSV数据处理
Import-Csv data.csv | ForEach-Object {
    $_.Prices = [double[]]$_.Prices.Split('|')
}
```