---
layout: post
date: 2024-08-01 08:00:00
title: "PowerSwitch 模式匹配实战指南"
description: "解锁条件分支的高级应用场景"
categories:
- powershell
- scripting
tags:
- flow-control
- switch
---

### 通配符模式匹配
```powershell
$process = 'powershell_ise'

switch -Wildcard ($process)
{
    '*sql*' { '数据库相关进程' }
    'power*' { 
        if($_.Length -gt 10) {
            '长进程名PowerShell组件'
        }
    }
    default { '未识别进程类型' }
}
```

### 正则表达式模式
```powershell
$logEntry = 'ERROR [2024-07-15] : File not found: config.json'

switch -Regex ($logEntry)
{
    '^WARN'  { Write-Host '警告级别日志' -ForegroundColor Yellow }
    '^ERROR' {
        $matches = $_ -match '\d{4}-\d{2}-\d{2}'
        Write-Host "严重错误于$($matches[0])" -ForegroundColor Red
    }
    'config' { Send-Alert -Type '配置缺失' }
}
```

### 脚本块条件
```powershell
$num = 42

switch ($num)
{
    { $_ -is [string] }   { '字符串类型' }
    { $_ % 2 -eq 0 }      { '偶数数字' }
    { $_ -gt [math]::PI } { '大于圆周率' }
}
```

### 最佳实践
1. 优先使用-exact参数避免意外匹配
2. 通过fallthrough关键词控制执行流
3. 结合break/continue控制循环上下文
4. 使用parallel参数加速大数据处理