---
layout: post
date: 2024-04-05 08:00:00
title: "PowerShell字符串操作实用指南"
description: "掌握文本处理的核心方法与效率优化"
categories:
- powershell
- basic
---

## 基础操作演示
```powershell
# 字符串拼接优化
$result = -join ('Power','Shell','2024')

# 多行字符串处理
$text = @"
第一行内容
第二行内容
"@
```

## 常用处理方法
| 方法         | 描述                | 示例                     |
|--------------|---------------------|--------------------------|
| Split()      | 分割字符串          | 'a,b,c'.Split(',')       |
| Replace()    | 替换字符            | '123-456'.Replace('-','') |
| Substring()  | 截取子串            | 'abcdef'.Substring(2,3)   |

## 性能对比测试
```powershell
# 拼接方式效率对比
Measure-Command { 1..10000 | %{ $str += $_ } } # 2.1s
Measure-Command { -join (1..10000) }            # 0.03s
```

## 调试技巧
```powershell
# 显示特殊字符
[System.BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes($string))
```

## 最佳实践
1. 优先使用-join运算符拼接大量字符串
2. 避免在循环中进行字符串修改操作
3. 使用StringBuilder处理动态内容