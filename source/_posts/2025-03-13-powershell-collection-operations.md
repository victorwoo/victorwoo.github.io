---
layout: post
date: 2025-03-13 08:00:00
title: "PowerShell 技能连载 - 集合操作方法"
description: PowerTip of the Day - PowerShell Collection Operations
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 基础集合操作

```powershell
# 创建强类型集合
[System.Collections.Generic.List[string]]$list = @()
$list.AddRange(@('Server01','Server02'))

# 哈希表快速查询
$configTable = @{
    Timeout = 30
    Retries = 3
    LogPath = 'C:\Logs'
}
$configTable.ContainsKey('Timeout')
```

## 应用场景
1. **数据过滤**：
```powershell
Get-Process | Where-Object {$_.CPU -gt 100 -and $_.Name -notmatch '^svchost$'}
```

2. **批量重命名**：
```powershell
$files = Get-ChildItem *.log
$files | ForEach-Object {
    $newName = $_.Name -replace '_old','_new'
    Rename-Item $_ $newName
}
```

## 最佳实践
1. 使用泛型集合提升性能
```powershell
$queue = [System.Collections.Queue]::new()
1..10000 | ForEach-Object {$queue.Enqueue($_)}
```

2. 利用管道优化内存使用
```powershell
# 流式处理大文件
Get-Content huge.log | Where-Object {$_ -match 'ERROR'} | Export-Csv errors.csv
```

3. 嵌套集合处理
```powershell
$serverData = @(
    [PSCustomObject]@{Name='WEB01'; Role='Frontend'}
    [PSCustomObject]@{Name='DB01'; Role='Database'}
)

$serverData.Where({$_.Role -eq 'Frontend'}).ForEach({$_.Name})
```