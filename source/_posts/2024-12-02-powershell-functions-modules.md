---
layout: post
date: 2024-12-02 08:00:00
title: "PowerShell函数与模块化开发"
description: "掌握代码复用与组织的基本方法"
categories:
- powershell
- basic
---

## 函数定义基础
```powershell
# 基础函数示例
function Get-SystemInfo {
    param($ComputerName = $env:COMPUTERNAME)
    Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName
}

# 调用带参数的函数
Get-SystemInfo -ComputerName Localhost
```

## 模块化开发
| 文件结构       | 功能描述               |
|----------------|------------------------|
| MyModule.psm1 | 包含函数定义           |
| MyModule.psd1 | 模块清单文件           |

## 参数验证示例
```powershell
function Set-DiskSpace {
    param(
        [ValidateRange(10GB,100GB)]
        [int]$MinSize
    )
    Get-Volume | Where-Object SizeRemaining -lt $MinSize
}
```

## 最佳实践建议
1. 使用动词-名词命名规范
2. 限制函数复杂度（不超过50行）
3. 为重要参数添加验证属性
4. 使用注释式帮助文档

## 调试技巧
```powershell
# 查看函数定义
Get-Command Get-SystemInfo -Syntax

# 跟踪函数执行
Set-PSDebug -Trace 2
Get-SystemInfo
```