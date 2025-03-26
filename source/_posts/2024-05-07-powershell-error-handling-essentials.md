---
layout: post
date: 2024-05-07 08:00:00
title: "PowerShell错误处理核心机制"
description: "全面解析try/catch与错误变量应用场景"
categories:
- powershell
- scripting
tags:
- error-handling
- debugging
---

## 基础错误捕获结构
```powershell
try {
    Get-Content 'nonexistent.txt' -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Host "文件未找到: $($_.Exception.Message)"
}
catch {
    Write-Host "未知错误: $($_.Exception.GetType().FullName)"
}
finally {
    # 清理资源代码
}
```

## 错误变量解析
```powershell
# 自动变量应用示例
$Error[0] | Format-List * -Force
$Error.Clear()
$ErrorActionPreference = 'Continue'
```

## 自定义错误抛出
```powershell
function Validate-Range {
    param([int]$Value)
    if ($Value -notin 1..100) {
        throw [System.ArgumentOutOfRangeException]::new('Value')
    }
}
```

## 最佳实践
1. 优先使用强类型异常捕获
2. 合理设置ErrorActionPreference
3. 保持finally块简洁
4. 记录完整错误堆栈信息