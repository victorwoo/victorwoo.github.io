---
layout: post
date: 2018-05-03 00:00:00
title: "PowerShell 技能连载 - WMI 快速入门（第 1 部分）"
description: PowerTip of the Day - WMI Quick Primer (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
WMI 是管理员的一个有用的信息源。您所需要的知识 WMI 类的名字，它代表了您感兴趣的东西。查找合法的 WMI 类名的最简单方法是搜索。

这行代码返回所有名字中包含 "Share" 的类：

```powershell
Get-WmiObject -Class *share* -List
```

下一步，用 `Get-WmiObject` 获取一个类的所有实例：

```powershell
Get-WmiObject -Class win32_share
```

如果您想查看所有属性，请别忘了将结果通过管道输出到 `Select-Object` 指令：

```powershell
Get-WmiObject -Class win32_share | Select-Object -Property *
```

一个更好的方法是使用 `Get-CimInstance` 而不是 `Get-WmiObject` 因为它能自动转换数据类型，例如 `DateTime`。

这个调用和 `Get-WmiObject` 的效果基本相同：

```powershell
Get-CimInstance -ClassName Win32_Share
```

现在，您可以看到其中的区别：

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object -Property Name, LastBootupTime, OSType

Get-WmiObject -Class Win32_OperatingSystem |
    Select-Object -Property Name, LastBootupTime, OSType
```

<!--more-->
本文国际来源：[WMI Quick Primer (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/wmi-quick-primer-part-1)
