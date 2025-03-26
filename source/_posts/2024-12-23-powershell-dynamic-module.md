---
layout: post
date: 2024-12-23 08:00:00
title: "PowerShell动态模块加载技术"
description: "解锁运行时模块操作与混合编程能力"
categories:
- powershell
- module-system
tags:
- dynamic-loading
- unmanaged-code
---

## 运行时DLL加载
```powershell
# 动态加载Win32 API
$signature = @"
[DllImport("user32.dll")]
public static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);
"@

$MessageBox = Add-Type -MemberDefinition $signature -Name 'Win32Msg' -PassThru
$MessageBox::MessageBox(0, '动态加载演示', 'PowerShell', 0)
```

## 模块卸载技巧
```powershell
# 创建可卸载模块
$module = New-Module -Name TempModule -ScriptBlock {
    function Get-HiddenInfo {
        [Environment]::OSVersion.VersionString
    }
} -AsCustomObject

# 显式卸载模块
Remove-Module -ModuleInfo $module -Force
```

## 混合编程实现
```powershell
# 嵌入C#代码动态编译
$csharpCode = @"
public class Calculator {
    public int Add(int a, int b) => a + b;
}
"@

Add-Type -TypeDefinition $csharpCode -OutputAssembly Calculator.dll
[Calculator]::new().Add(5, 3)
```

## 热更新应用场景
1. 实时调试脚本组件
2. 安全模块动态替换
3. 多版本API并行测试
4. 内存驻留程序补丁

## 注意事项
- 32/64位兼容性问题
- 全局程序集缓存冲突
- 内存泄漏风险控制
- 签名验证机制强化