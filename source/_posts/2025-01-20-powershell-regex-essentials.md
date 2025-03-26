---
layout: post
date: 2025-01-20 08:00:00
title: "PowerShell正则表达式实战指南"
description: "掌握模式匹配与文本处理的核心理念"
categories:
- powershell
- basic
---

## 正则表达式基础语法
```powershell
# 邮箱验证模式
$emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$'

# 使用-match运算符
'user@domain.com' -match $emailPattern
```

## 文本替换实战
```powershell
# 电话号码格式标准化
$text = '联系客服：138-1234-5678'
$text -replace 'D','' -replace '(d{3})(d{4})(d{4})','$1 $2 $3'
```

## 模式匹配技巧
1. 使用非贪婪匹配符`.*?`
2. 通过`(?=)`实现正向预查
3. 利用命名捕获组提升可读性
4. 特殊字符的转义处理策略

## 性能优化建议
```powershell
# 预编译正则表达式提升性能
$regex = [regex]::new('\d+', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regex.Matches('订单号：20240522001')