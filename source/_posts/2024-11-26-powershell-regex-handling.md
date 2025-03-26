---
layout: post
date: 2024-11-26 08:00:00
title: "PowerShell 技能连载 - 正则表达式实战技巧"
description: "掌握PowerShell中正则表达式的高效应用方法"
categories:
- powershell
- scripting
tags:
- powershell
- regex
- text-processing
---

正则表达式是文本处理的核心工具，PowerShell通过`-match`和`-replace`运算符提供原生支持。

```powershell
# 提取日志中的IP地址
$logContent = Get-Content app.log -Raw
$ipPattern = '\b(?:\d{1,3}\.){3}\d{1,3}\b'

$matches = [regex]::Matches($logContent, $ipPattern)
$matches.Value | Select-Object -Unique
```

### 模式匹配进阶技巧
1. 使用命名捕获组提取结构化数据：
```powershell
$text = '订单号: INV-2024-0456 金额: ¥1,234.56'
$pattern = '订单号:\s+(?<OrderID>INV-\d+-\d+)\s+金额:\s+¥(?<Amount>[\d,]+\.[\d]{2})'

if ($text -match $pattern) {
    [PSCustomObject]@{
        OrderID = $matches['OrderID']
        Amount = $matches['Amount'] -replace ',',''
    }
}
```

2. 多行模式处理复杂文本：
```powershell
$multiLineText = @'
Server: svr01
CPU: 85%
Memory: 92%
---
Server: svr02
CPU: 63%
Memory: 78%
'@

$pattern = '(?m)^Server:\s+(.+)\nCPU:\s+(.+)\nMemory:\s+(.+)$'
[regex]::Matches($multiLineText, $pattern) | ForEach-Object {
    [PSCustomObject]@{
        Server = $_.Groups[1].Value
        CPU = $_.Groups[2].Value
        Memory = $_.Groups[3].Value
    }
}
```

最佳实践：
- 使用`[regex]::Escape()`处理特殊字符
- 通过`(?:)`语法优化非捕获组
- 利用`RegexOptions`枚举加速匹配
- 使用在线正则测试工具验证模式