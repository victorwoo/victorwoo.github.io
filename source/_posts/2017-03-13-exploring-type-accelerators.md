---
layout: post
date: 2017-03-13 00:00:00
title: "PowerShell 技能连载 - 探索类型加速器"
description: PowerTip of the Day - Exploring Type Accelerators
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 使用了大量所谓类型加速器来简化过长的 .NET 类型名。例如 "System.DirectoryServices.DirectoryEntry" 可以简化为 "ADSI"。

当您需要查询一个类型的完整名称时，您可以获取到实际的完整 .NET 类型名：

```powershell
PS C:\> [ADSI].FullName
System.DirectoryServices.DirectoryEntry

PS C:\>
```

以下代码在 PowerShell 中输出所有的内置 .NET 类型加速器：

```powershell
[PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get |
    Out-GridView
```

除了显式的类型加速器之外，还有一个 PowerShell 内置的规则：在 `System` 命名空间中的类型加速器可以省略命名空间。所以以下的表达完全一致：

```powershell
PS C:\> [int].FullName
System.Int32

PS C:\> [System.Int32].FullName
System.Int32

PS C:\> [Int32].FullName
System.Int32
```

<!--本文国际来源：[Exploring Type Accelerators](http://community.idera.com/powershell/powertips/b/tips/posts/exploring-type-accelerators)-->
