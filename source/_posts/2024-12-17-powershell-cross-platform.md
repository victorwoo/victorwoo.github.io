---
layout: post
date: 2024-12-17 08:00:00
title: "PowerShell跨平台开发实战"
description: "掌握Linux/Windows双环境脚本适配技巧"
categories:
- powershell
- cross-platform
tags:
- path-handling
- conditional-compilation
---

## 智能路径转换
```powershell
function Get-UniversalPath {
    param([string]$Path)
    if ($IsLinux) {
        $Path.Replace('\', '/').TrimEnd('/')
    } else {
        $Path.Replace('/', '\').TrimEnd('\')
    }
}

# 示例：转换C:/Users到Linux格式
Get-UniversalPath -Path 'C:\Users\Demo' # 输出 /mnt/c/Users/Demo
```

## 条件编译技巧
```powershell
#region WindowsOnly
if ($PSVersionTable.Platform -eq 'Win32NT') {
    Add-Type -AssemblyName PresentationCore
    [System.Windows.Clipboard]::SetText($content)
}
#endregion

#region LinuxOnly
if ($IsLinux) {
    $tempFile = New-TemporaryFile
    $content | Out-File $tempFile
    xclip -selection clipboard -in $tempFile
}
#endregion
```

## 原生命令封装
```powershell
function Invoke-NativeCommand {
    param([string]$Command)
    if ($IsWindows) {
        cmd.exe /c $Command
    } else {
        bash -c $Command
    }
}

# 跨平台调用系统命令
Invoke-NativeCommand -Command 'echo $Env:COMPUTERNAME'
```

## 开发注意事项
- 区分文件系统大小写敏感特性
- 处理CRLF/LF行尾差异
- 避免平台特定别名使用
- 统一字符编码为UTF-8