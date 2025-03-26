---
layout: post
date: 2024-06-06 08:00:00
title: "PowerShell参数传递机制详解"
description: "掌握位置参数与命名参数的核心差异"
categories:
- powershell
- basic
---

## 参数类型解析
```powershell
# 位置参数示例
function Get-Sum {
    param($a, $b)
    $a + $b
}
Get-Sum 10 20

# 命名参数优势
Get-Sum -b 30 -a 15
```

## 参数验证对比
| 验证类型       | 适用场景       | 错误提示  |
|----------------|----------------|-----------|
| [ValidateSet] | 限定取值范围   | 明确选项  |
| [ValidatePattern] | 正则匹配   | 模式说明  |
| [ValidateRange]  | 数值范围控制 | 边界提示  |

## 典型应用场景
1. 通过ValueFromPipeline实现流式参数处理
2. 使用Parameter(Mandatory)强制必需参数
3. 通过[switch]参数实现布尔开关
4. 动态参数的条件化呈现

## 常见错误解析
```powershell
# 未处理参数缺失错误
function Get-Product {
    param($x, $y)
    $x * $y
}
Get-Product -x 5  # 触发参数绑定异常

# 正确的参数默认值设置
function Get-Discount {
    param(
        [Parameter(Mandatory)]
        $Price,
        $Rate = 0.9
    )
    $Price * $Rate
}
```