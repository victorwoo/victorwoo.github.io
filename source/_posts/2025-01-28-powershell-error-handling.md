---
layout: post
date: 2025-01-28 08:00:00
title: "PowerShell 异常处理完全指南"
description: "掌握try/catch块与错误类型过滤技巧"
categories:
- powershell
- scripting
tags:
- error-handling
- debugging
---

### 结构化异常捕获
```powershell
try {
    # 可能失败的操作
    Get-Content -Path '不存在的文件.txt' -ErrorAction Stop
    Invoke-RestMethod -Uri 'http://无效域名'
}
catch [System.IO.FileNotFoundException] {
    Write-Warning "文件未找到: $($_.Exception.ItemName)"
}
catch [System.Net.WebException] {
    Write-Warning "网络错误: $($_.Exception.Status)"
}
catch {
    Write-Error "未捕获的异常: $_"
}
finally {
    # 清理资源
    Remove-Variable -Name '*temp*' -ErrorAction SilentlyContinue
}
```

### 错误处理模式
1. **终止错误**：使用-ErrorAction Stop强制转换
2. **非终止错误**：通过$Error自动变量追踪
3. **类型过滤**：catch块支持.NET异常类型匹配
4. **错误记录**：$Error[0]获取最近异常详细信息

### 最佳实践
- 在函数内使用throw生成可预测异常
- 避免空catch块吞噬异常
- 使用-ErrorVariable参数捕获错误对象
- 通过$ErrorView控制错误显示格式