---
layout: post
date: 2024-06-10 08:00:00
title: "PowerShell正则表达式核心指南"
description: "掌握模式匹配与文本解析的核心技巧"
categories:
- powershell
- basic
---

## 基础模式匹配
```powershell
# 简单匹配示例
'PSVersion: 5.1' -match '\d+\.\d+'
$matches[0]  # 输出5.1

# 多行匹配技巧
$text = @"
Error: 0x80070005
Warning: 0x80040001
"@
$text | Select-String -Pattern '0x[0-9a-f]{8}'
```

## 常用操作符对比
| 方法            | 作用域       | 返回类型  |
|-----------------|--------------|-----------|
| -match          | 标量匹配     | 布尔      |
| -replace        | 替换操作     | 字符串    |
| Select-String   | 流式处理     | MatchInfo |

## 典型应用场景
1. 日志文件中的错误代码提取
2. 配置文件参数值替换
3. 结构化文本数据解析
4. 输入验证中的格式检查

## 性能优化建议
```powershell
# 避免重复编译正则表达式
$regex = [regex]::new('^\d{4}-\d{2}-\d{2}$')
$regex.IsMatch('2024-04-18')

# 正确使用贪婪/惰性量词
'<div>content</div>' -match '<div>(.*?)</div>'  # 惰性匹配
```