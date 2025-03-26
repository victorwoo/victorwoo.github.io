---
layout: post
date: 2024-07-30 08:00:00
title: "PowerShell字符串操作完全指南"
description: "掌握文本处理与格式化的核心方法"
categories:
- powershell
- basic
---

## 基础字符串操作
```powershell
# 多行字符串处理
$text = @"
系统日志条目：
时间: $(Get-Date)
事件: 用户登录
"@
$text -replace '\s+',' ' -split '
'

# 字符串格式化演示
"{0}的存款利率为{1:P}" -f '工商银行', 0.035
```

## 高级处理技巧
```powershell
# 正则表达式分割
$csvData = '姓名,年龄,职业;张三,30,工程师'
$csvData -split '[;,]' | Group-Object { $_ -match '\d+' }

# 字符串构建优化
$sb = [System.Text.StringBuilder]::new()
1..100 | ForEach-Object { $null = $sb.Append("条目$_") }
$sb.ToString()
```

## 实用场景建议
1. 使用Trim系列方法处理首尾空白
2. 通过PadLeft/PadRight实现对齐格式
3. 优先使用-f格式化运算符代替字符串拼接
4. 处理大文本时使用StringBuilder