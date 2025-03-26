---
layout: post
date: 2024-04-29 08:00:00
title: "PowerShell正则表达式入门精要"
description: "掌握文本模式匹配的核心技巧"
categories:
- powershell
- basic
---

## 基础匹配模式
```powershell
# 邮箱验证正则
$emailPattern = '^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'
'test@example.com' -match $emailPattern  # 返回True

# 提取电话号码
$text = '联系电话：010-12345678 或 13800138000'
$text -match '\d{3,4}-\d{7,8}'
$matches[0]  # 输出010-12345678
```

## 正则表达式元字符
| 字符 | 功能描述          | 示例         |
|------|-------------------|--------------|
| .    | 匹配任意字符       | a.c → abc   |
| \d  | 匹配数字           | \d{3} → 123 |
| \w  | 匹配字母数字下划线 | \w+ → abc123|
| ^    | 匹配行首           | ^Start      |
| $    | 匹配行尾           | end$        |

## 替换操作示例
```powershell
# 日期格式转换
'2024-04-07' -replace '(\d{4})-(\d{2})-(\d{2})','$3/$2/$1'
# 输出07/04/2024

# 清理多余空格
'PowerShell  正则  教程' -replace '\s+',' '
# 输出PowerShell 正则 教程
```

## 性能优化建议
1. 预编译常用正则表达式
2. 避免贪婪匹配引发性能问题
3. 使用非捕获组(?:)减少内存开销