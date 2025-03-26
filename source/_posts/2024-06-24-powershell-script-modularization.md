---
layout: post
date: 2024-06-24 08:00:00
title: "PowerShell 技能连载 - 脚本模块化设计"
description: PowerTip of the Day - PowerShell Script Modularization
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---

## 模块化基础

```powershell
# 函数封装示例
function Get-SystemHealth {
    [CmdletBinding()]
    param(
        [ValidateSet('Basic','Full')]
        [string]$DetailLevel = 'Basic'
    )
    # 健康检查逻辑...
}

# 模块导出配置
Export-ModuleMember -Function Get-SystemHealth
```

## 应用场景
1. **自动化脚本包**：
```powershell
# 模块目录结构
MyModule/
├── Public/
│   └── Get-SystemHealth.ps1
└── MyModule.psd1
```

2. **模块分发使用**：
```powershell
# 安装模块
Copy-Item -Path ./MyModule -Destination $env:PSModulePath.Split(';')[0] -Recurse
Import-Module MyModule
```

## 最佳实践
1. 分离公共/私有函数
2. 实现模块帮助文档
3. 版本控制规范：
```powershell
# 模块清单配置
@{
    ModuleVersion = '1.2.0'
    FunctionsToExport = @('Get-SystemHealth')
    RequiredModules = @('PSScriptAnalyzer')
}
```

4. 依赖管理：
```powershell
# 需求声明
#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.1'}
#Requires -Version 7.0
```