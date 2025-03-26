---
layout: post
date: 2024-10-04 08:00:00
title: "PowerShell 技能连载 - JSON 数据处理技巧"
description: PowerTip of the Day - PowerShell JSON Data Handling Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 JSON 数据变得越来越常见，特别是在与 Web API 交互或处理配置文件时。本文将介绍一些实用的 JSON 处理技巧。

首先，让我们看看如何创建和转换 JSON 数据：

```powershell
# 创建 JSON 对象
$userData = @{
    name = "张三"
    age = 30
    hobbies = @("读书", "编程", "摄影")
    contact = @{
        email = "zhangsan@example.com"
        phone = "123-456-7890"
    }
}

# 转换为 JSON 字符串
$jsonString = $userData | ConvertTo-Json -Depth 10
Write-Host "JSON 字符串："
Write-Host $jsonString

# 从 JSON 字符串转换回对象
$object = $jsonString | ConvertFrom-Json
Write-Host "`n转换回对象："
$object | Format-List
```

处理复杂的 JSON 数据时，我们可以使用自定义对象：

```powershell
# 创建自定义对象并转换为 JSON
$customObject = [PSCustomObject]@{
    id = 1
    title = "PowerShell 技巧"
    author = "李四"
    tags = @("PowerShell", "自动化", "脚本")
    metadata = @{
        created = Get-Date
        version = "1.0.0"
    }
}

# 转换为 JSON 并保存到文件
$customObject | ConvertTo-Json -Depth 10 | Set-Content "article.json"

# 从文件读取 JSON
$loadedData = Get-Content "article.json" | ConvertFrom-Json
```

处理 API 响应时的一些实用技巧：

```powershell
# 处理 API 响应
$apiResponse = @'
{
    "status": "success",
    "data": {
        "users": [
            {
                "id": 1,
                "name": "王五",
                "role": "admin"
            },
            {
                "id": 2,
                "name": "赵六",
                "role": "user"
            }
        ],
        "total": 2
    }
}
'@

# 解析 JSON 并访问嵌套数据
$response = $apiResponse | ConvertFrom-Json
$adminUsers = $response.data.users | Where-Object { $_.role -eq "admin" }
Write-Host "管理员用户："
$adminUsers | Format-Table
```

处理大型 JSON 文件时的性能优化：

```powershell
# 使用流式处理大型 JSON 文件
$jsonStream = [System.IO.File]::OpenRead("large-data.json")
$reader = [System.IO.StreamReader]::new($jsonStream)
$jsonText = $reader.ReadToEnd()
$reader.Close()
$jsonStream.Close()

# 使用 System.Text.Json 进行高性能解析
Add-Type -AssemblyName System.Text.Json
$jsonDoc = [System.Text.Json.JsonDocument]::Parse($jsonText)

# 访问特定属性
$value = $jsonDoc.RootElement.GetProperty("specificField").GetString()
```

一些实用的 JSON 处理技巧：

1. 使用 `-Compress` 参数创建紧凑的 JSON：
```powershell
$data | ConvertTo-Json -Compress
```

2. 处理日期时间格式：
```powershell
$dateObject = @{
    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json
```

3. 验证 JSON 格式：
```powershell
function Test-JsonFormat {
    param([string]$JsonString)
    try {
        $null = $JsonString | ConvertFrom-Json
        return $true
    }
    catch {
        return $false
    }
}
```

这些技巧将帮助您更有效地处理 JSON 数据。记住，在处理敏感数据时，始终要注意数据安全性，并考虑使用适当的加密方法。

<!--本文国际来源：[PowerShell JSON Data Handling Tips](https://blog.idera.com/database-tools/powershell/powertips/powershell-json-data-handling-tips/)--> 