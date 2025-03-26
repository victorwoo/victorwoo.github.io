---
layout: post
date: 2024-07-09 08:00:00
title: "PowerShell错误处理核心技巧"
description: "掌握脚本异常捕获与调试方法"
categories:
- powershell
- basic
---

## 错误类型与捕获
```powershell
# 基础异常捕获
Try {
    Get-Content '不存在的文件.txt' -ErrorAction Stop
}
Catch {
    Write-Host "捕获到错误: $_"
}
Finally {
    Write-Host "清理操作"
}
```

## 错误信息分析
| 属性       | 描述                   |
|------------|------------------------|
| $_.Message | 错误描述信息           |
| $_.FullyQualifiedErrorId | 错误唯一标识符 |
| $_.Exception | 原始异常对象       |

## 高级错误处理
```powershell
# 筛选特定错误类型
Try {
    1/0
}
Catch [System.DivideByZeroException] {
    Write-Host "除零错误"
}
Catch {
    Write-Host "其他错误"
}
```

## 自定义错误
```powershell
# 抛出业务异常
function Test-Value {
    param($val)
    if ($val -lt 0) {
        throw [System.ArgumentException]::new("值不能为负")
    }
}
```

## 调试技巧
1. 使用$Error自动变量查看历史错误
2. 设置-Debug参数输出调试信息
3. 使用Set-PSDebug -Trace 1进行脚本追踪