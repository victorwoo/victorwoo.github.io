---
layout: post
date: 2025-03-07 08:00:00
title: "PowerShell流程控制结构精解"
description: "掌握循环与条件语句的核心应用场景"
categories:
- powershell
- basic
---

## 循环结构实战
```powershell
# 集合遍历优化
$processList = Get-Process
foreach ($process in $processList.Where{ $_.CPU -gt 100 }) {
    "高CPU进程: $($process.Name)"
}

# 并行处理演示
1..10 | ForEach-Object -Parallel {
    "任务 $_ 开始于: $(Get-Date)"
    Start-Sleep -Seconds 1
}
```

## 条件判断进阶
```powershell
# 多条件筛选模式
$score = 85
switch ($score) {
    { $_ -ge 90 } { "优秀" }
    { $_ -ge 75 } { "良好" }
    default { "待提高" }
}
```

## 最佳实践
1. 避免在循环内执行耗时操作
2. 使用break/continue优化循环效率
3. 优先使用管道代替传统循环
4. 合理设置循环终止条件防止死循环