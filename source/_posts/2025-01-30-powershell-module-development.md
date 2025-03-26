---
layout: post
date: 2025-01-30 08:00:00
title: "PowerShell模块开发入门指南"
description: "从零开始构建标准化PowerShell模块"
categories:
- powershell
- development
tags:
- module
- packaging
---

## 模块基础结构
```powershell
# 创建模块目录结构
New-Item -Path MyModule\Public -ItemType Directory
New-Item -Path MyModule\Private -ItemType Directory
New-Item -Path MyModule\MyModule.psd1 -ItemType File
```

## 清单文件配置
```powershell
@{
    ModuleVersion = '1.0'
    RootModule = 'MyModule.psm1'
    FunctionsToExport = @('Get-SystemInfo')
    RequiredModules = @('PSScriptAnalyzer')
}
```

## 函数导出实践
```powershell
function Get-SystemInfo {
    [CmdletBinding()]
    param()
    
    $os = Get-CimInstance Win32_OperatingSystem
    [PSCustomObject]@{
        OSName = $os.Caption
        Version = $os.Version
        InstallDate = $os.InstallDate
    }
}
```

## 模块发布流程
```powershell
# 生成模块清单
New-ModuleManifest -Path .\MyModule\MyModule.psd1 \
    -Author 'YourName' \
    -Description '系统信息获取模块'

# 发布到本地仓库
Publish-Module -Path .\MyModule \
    -Repository LocalRepo \
    -NuGetApiKey 'AzureDevOps'
```