---
layout: post
date: 2024-07-11 08:00:00
title: "PowerShell模块系统深度解析"
description: "掌握模块化编程与代码复用的核心机制"
categories:
- powershell
- basic
---

## 模块创建与导入
```powershell
# 创建简单模块
New-Item -Path ./MyModule.psm1 -Value @'
function Get-Msg {
    param([string]$name)
    "Hello, $name!"
}
'@

# 模块导入方式对比
Import-Module ./MyModule.psm1 -Force
Get-Msg -name "开发者"
```

## 常用模块推荐
1. Pester：单元测试框架
2. PSReadLine：命令行增强
3. dbatools：数据库管理
4. Az：Azure云管理

## 模块管理技巧
```powershell
# 查看已加载模块
Get-Module | Format-Table Name,Version

# 自动加载配置
$env:PSModulePath += ";$HOME\Documents\PowerShell\Modules"

# 模块版本控制
Install-Module Pester -RequiredVersion 5.3.1 -Scope CurrentUser
```