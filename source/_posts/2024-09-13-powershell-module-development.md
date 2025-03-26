---
layout: post
date: 2024-09-13 08:00:00
title: "PowerShell模块化开发实践指南"
description: "掌握脚本模块创建与管理的核心方法"
categories:
- powershell
- basic
---

## 模块创建流程
```powershell
# 新建模块文件
New-ModuleManifest -Path MyModule.psd1

# 导出模块函数
Export-ModuleMember -Function Get-SystemInfo
```

## 模块要素对比
| 组件           | 作用               | 存储位置  |
|----------------|--------------------|-----------|
| .psm1文件      | 模块主体代码       | 模块目录  |
| .psd1清单      | 元数据与依赖管理   | 模块目录  |
| 格式化文件     | 自定义对象显示规则 | Format目录|

## 典型应用场景
1. 通过NestedModules组织复杂模块结构
2. 使用RequiredModules声明模块依赖
3. 通过FileList控制模块文件发布范围
4. 利用ScriptsToProcess实现预加载脚本

## 常见错误解析
```powershell
# 未导出函数导致的访问错误
function Get-Data {}
Import-Module ./MyModule
Get-Data  # 命令不存在

# 正确的模块成员导出
Export-ModuleMember -Function Get-Data
```