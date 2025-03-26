---
layout: post
date: 2024-05-30 08:00:00
title: "PowerShell 技能连载 - 调试技巧解析"
description: PowerTip of the Day - PowerShell Debugging Techniques
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 调试基础工具

```powershell
# 设置行断点
Set-PSBreakpoint -Script test.ps1 -Line 15

# 变量监控断点
Set-PSBreakpoint -Script test.ps1 -Variable counter -Mode Write
```

## 调试场景实战
1. **条件断点**：
```powershell
Set-PSBreakpoint -Script service.ps1 -Line 42 -Action {
    if ($service.Status -ne 'Running') {
        break
    }
}
```

2. **远程调试**：
```powershell
Enter-PSHostProcess -Id 1234
Debug-Runspace -Runspace 1
```

## 最佳实践
1. 使用调试模式运行脚本：
```powershell
powershell.exe -File script.ps1 -Debug
```

2. 交互式调试命令：
```powershell
# 查看调用栈
Get-PSCallStack

# 单步执行
s

# 继续运行
c
```

3. 调试器增强配置：
```powershell
$DebugPreference = 'Continue'
function Debug-Info {
    [CmdletBinding()]
    param([string]$Message)
    Write-Debug $Message -Debug:$true
}
```

4. 异常捕获调试：
```powershell
trap {
    Write-Warning "异常类型: $($_.Exception.GetType().Name)"
    $host.EnterNestedPrompt()
    continue
}
```