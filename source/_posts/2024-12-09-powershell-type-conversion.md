---
layout: post
date: 2024-12-09 08:00:00
title: "PowerShell 技能连载 - 类型转换机制"
description: PowerTip of the Day - PowerShell Type Conversion
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 基本转换方法

```powershell
# 隐式转换
$numString = "123"
$result = $numString + 10  # 自动转换为int

# 显式转换
[datetime]$date = "2024-04-15"
[int]::Parse("0xFF", [System.Globalization.NumberStyles]::HexNumber)
```

## 应用场景
1. **字符串解析**：
```powershell
$userInput = Read-Host "请输入数字"
if ($userInput -as [int]) {
    # 安全转换成功
}
```

2. **类型验证**：
```powershell
try {
    [ValidateScript({$_ -as [uri]})]
    [uri]$url = "https://blog.vichamp.com"
}
catch {
    Write-Warning "无效的URL格式"
}
```

## 最佳实践
1. 优先使用-as操作符进行安全转换
2. 处理文化差异（CultureInfo）
3. 自定义转换逻辑：
```powershell
class Temperature {
    [double]$Celsius

    static [Temperature] Parse($input) {
        if ($input -match "(\d+)°C") {
            return [Temperature]@{Celsius = $matches[1]}
        }
        throw "无效的温度格式"
    }
}
```