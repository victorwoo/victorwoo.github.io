---
layout: post
date: 2024-09-26 08:00:00
title: "PowerShell集合类型操作指南"
description: "掌握数组与哈希表的核心操作方法"
categories:
- powershell
- basic
---

## 基础数据结构
```powershell
# 数组初始化与索引
$numbers = 1..5
$numbers[0] = 10  # 索引从0开始

# 哈希表键值操作
$user = @{Name='Alice'; Age=25}
$user['Department'] = 'IT'
```

## 操作对比表
| 方法          | 数组适用 | 哈希表适用 | 时间复杂度 |
|---------------|----------|------------|------------|
| Add()         | ×        | ✓          | O(1)       |
| Remove()      | ×        | ✓          | O(1)       |
| Contains()    | ✓        | ✓          | O(n)/O(1)  |

## 典型应用场景
1. 使用ArrayList实现动态数组
2. 通过OrderedDictionary保持插入顺序
3. 利用哈希表进行快速键值查找
4. 多维数组存储表格数据

## 常见错误解析
```powershell
# 固定大小数组修改错误
$fixedArray = @(1,2,3)
$fixedArray.Add(4)  # 抛出异常

# 正确使用动态集合
$list = [System.Collections.ArrayList]@(1,2,3)
$list.Add(4) | Out-Null
```