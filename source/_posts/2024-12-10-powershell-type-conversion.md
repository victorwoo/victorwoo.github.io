---
layout: post
date: 2024-12-10 08:00:00
title: "PowerShell数据类型转换实战指南"
description: "掌握显式与隐式转换的核心差异"
categories:
- powershell
- basic
---

## 基础转换原理
```powershell
# 隐式转换示例
$num = "123" + 456  # 自动转为字符串拼接
Write-Host $num    # 输出123456

# 显式转换最佳实践
[int]$count = [convert]::ToInt32("789", 10)
$count.GetType().Name  # 输出Int32
```

## 转换方法对比
| 方法            | 适用场景       | 异常处理  |
|-----------------|----------------|-----------|
| as操作符        | 安全类型转换   | 返回$null |
| Parse()         | 字符串转数值   | 抛出异常  |
| TryParse()      | 安全数值转换   | 返回布尔  |
| 强制类型声明     | 变量初始化     | 运行时错 |

## 典型应用场景
1. 从CSV文件读取数据时的自动类型推导
2. REST API响应结果的JSON反序列化
3. 数据库查询结果的类型适配
4. 用户输入验证时的安全转换

## 常见错误解析
```powershell
# 文化格式导致的转换失败
$value = "1,234"
try {
    [int]::Parse($value)
} catch {
    Write-Host "需指定NumberStyles.AllowThousands"
}

# 空值转换陷阱
$null -as [int]  # 返回$null而非0
[int]$undefined  # 触发运行时错误
```