---
layout: post
date: 2024-06-05 08:00:00
title: "PowerShell 技能连载 - 管道机制解析"
description: PowerTip of the Day - PowerShell Pipeline Mechanism
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 管道基础原理

```powershell
# 基础管道操作
Get-Process | Where-Object {$_.CPU -gt 100} | Sort-Object CPU -Descending

# 参数绑定模式
Get-ChildItem | ForEach-Object {
    $_.Name.ToUpper()
}
```

## 高级应用场景
1. **并行处理优化**：
```powershell
1..100 | ForEach-Object -Parallel {
    "Processing $_"
    Start-Sleep -Milliseconds 100
} -ThrottleLimit 5
```

2. **数据分块处理**：
```powershell
Get-Content bigfile.log | 
    Select-Object -First 1000 | 
    Group-Object -Property {$_.Substring(0,6)} 
```

## 最佳实践
1. 使用Begin/Process/End块：
```powershell
function Process-Files {
    param([Parameter(ValueFromPipeline)]$File)
    
    begin { $counter = 0 }
    process {
        $counter++
        "Processing file #{0}: {1}" -f $counter, $File.Name
    }
    end { "Total processed: $counter" }
}
```

2. 优化管道性能：
```powershell
# 避免不必要的格式转换
Get-Process | 
    Select-Object Name,CPU,WS | 
    Export-Csv processes.csv -NoTypeInformation
```

3. 错误处理机制：
```powershell
Get-Content filelist.txt | 
    ForEach-Object {
        try {
            Get-Item $_ -ErrorAction Stop
        }
        catch {
            Write-Warning "Missing file: $_"
        }
    }
```