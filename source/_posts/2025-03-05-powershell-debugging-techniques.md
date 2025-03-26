---
layout: post
date: 2025-03-05 08:00:00
title: "PowerShell脚本调试全攻略"
description: "掌握断点设置与变量追踪的核心技巧"
categories:
- powershell
- basic
---

## 调试基础工具
```powershell
# 设置行号断点
Set-PSBreakpoint -Script test.ps1 -Line 15

# 条件断点演示
Set-PSBreakpoint -Script test.ps1 -Line 20 -Action {
    if ($_.Count -gt 100) { break }
}
```

## 变量追踪技巧
```powershell
# 调试模式查看变量
$DebugPreference = 'Continue'
$processList = Get-Process
Write-Debug "当前进程数量: $($processList.Count)"

# 使用调试控制台
function Test-Function {
    [CmdletBinding()]
    param()
    $private:counter = 0
    # 在调试器中输入 $private:counter 查看私有变量
}
```

## 最佳实践
1. 使用Step-Into/Step-Over逐行调试
2. 通过$Host.EnterNestedPrompt进入嵌套调试环境
3. 结合ISE/VSCode图形化调试工具
4. 使用Write-Verbose输出调试信息