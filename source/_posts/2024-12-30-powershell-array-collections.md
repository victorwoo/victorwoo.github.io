---
layout: post
date: 2024-12-30 08:00:00
title: "PowerShell数组与集合操作精要"
description: "掌握数据结构处理的核心方法与性能优化"
categories:
- powershell
- basic
---

## 基础操作演示
```powershell
# 数组创建与扩展
$numbers = 1..5
$numbers += 6
$numbers.Where{ $_ -gt 3 }

# 哈希表快速构建
$profile = @{Name='张三'; Role='开发者'}
$profile.Keys | ForEach-Object { "$_ : $($profile[$_])" }
```

## 高效集合处理
```powershell
# 使用ArrayList提升性能
$list = [System.Collections.ArrayList]::new()
1..10000 | ForEach-Object { $null = $list.Add($_) }

# 泛型列表应用
$genericList = [System.Collections.Generic.List[int]]::new()
$genericList.AddRange((1..100))
```

## 注意事项
1. 避免使用+=追加大型数组
2. 优先使用管道处理大数据集
3. 明确集合类型提升处理效率
4. 类型强转时的空值处理策略