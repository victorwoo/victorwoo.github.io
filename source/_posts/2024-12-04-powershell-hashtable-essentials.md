---
layout: post
date: 2024-12-04 08:00:00
title: "PowerShell哈希表实战指南"
description: "从基础操作到高级应用场景全解析"
categories:
- powershell
- scripting
tags:
- data-structure
- hashtable
---

## 哈希表基础操作
```powershell
# 创建基础哈希表
$userProfile = @{
    Name = '张三'
    Department = 'IT'
    LastLogin = (Get-Date).AddDays(-3)
}

# 属性访问的三种方式
Write-Host $userProfile['Name']
Write-Host $userProfile.Name
Write-Host $userProfile.Item('Department')
```

## 动态操作技巧
```powershell
# 条件性添加属性
if (-not $userProfile.ContainsKey('Office')) {
    $userProfile.Add('Office', 'Room 501')
}

# 带类型约束的哈希表
[ordered][System.Collections.Hashtable]$configTable = @{
    LogLevel = 'Debug'
    MaxRetry = 3
}
```

## 实际应用场景
```powershell
# 配置文件转换示例
$rawConfig = Get-Content appsettings.json | ConvertFrom-Json
$configTable = @{
    Environment = $rawConfig.Env
    Features = $rawConfig.Features -join ';'
    Timeout = [timespan]::FromMinutes($rawConfig.WaitTime)
}

# 快速对象比较
$diff = Compare-Object $oldTable.GetEnumerator() $newTable.GetEnumerator() -Property Name,Value
```