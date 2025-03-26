---
layout: post
date: 2025-02-11 08:00:00
title: "PowerShell 技能连载 - 正则表达式实战"
description: PowerTip of the Day - Regular Expression Applications
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 正则表达式基础

```powershell
# 邮箱验证模式
$emailPattern = '^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$'

# 匹配操作
if ('user@domain.com' -match $emailPattern) {
    Write-Output "有效邮箱地址"
}
```

## 高级应用场景
1. **批量重命名文件**：
```powershell
Get-ChildItem *.log | 
Rename-Item -NewName { $_.Name -replace '_\d{8}_','_$(Get-Date -f yyyyMMdd)_' }
```

2. **日志分析提取**：
```powershell
Select-String -Path *.log -Pattern 'ERROR (\w+): (.+)' | 
ForEach-Object {
    [PSCustomObject]@{
        Code = $_.Matches.Groups[1].Value
        Message = $_.Matches.Groups[2].Value
    }
}
```

## 最佳实践
1. 使用命名捕获组增强可读性：
```powershell
$logEntry = '2024-04-22 14:35 [WARN] Disk space below 10%'
if ($logEntry -match '(?<Date>\d{4}-\d{2}-\d{2}).+\[(?<Level>\w+)\] (?<Message>.+)') {
    $matches['Level']
}
```

2. 预编译常用模式提升性能：
```powershell
$ipPattern = [regex]::new('^\d{1,3}(\.\d{1,3}){3}$')
if ($ipPattern.IsMatch('192.168.1.1')) {
    # IP地址验证逻辑
}
```

3. 多行模式处理复杂文本：
```powershell
$multiLineText = Get-Content -Raw data.txt
$matches = $multiLineText | Select-String -Pattern '(?s)<start>(.*?)<end>'
```