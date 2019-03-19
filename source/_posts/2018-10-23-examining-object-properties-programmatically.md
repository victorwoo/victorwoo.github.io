---
layout: post
date: 2018-10-23 00:00:00
title: "PowerShell 技能连载 - 编程检查对象属性"
description: PowerTip of the Day - Examining Object Properties Programmatically
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您用 `Import-Csv` 将一个 CSV 列表导入 PowerShell，或用任何其它类型的对象来处理时：如何自动确定对象的属性？以下是一个简单的方法：

```powershell
# take any object, and dump a list of its properties
Get-Process -Id $pid |
    Get-Member -MemberType *property |
    Select-Object -ExpandProperty Name |
    Sort-Object
```

为什么这种方法有用？有许多使用场景。例如，您可以检测一个注册表键的名称，支持用通配符转储所有的命令：

```powershell
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

# get actual registry values from path
$Values = Get-ItemProperty -Path $RegPath

# exclude default properties
$default = 'PSChildName','PSDrive','PSParentPath','PSPath','PSProvider'

# each value surfaces as object property
# get property (value) names
$keyNames = $Values |
    Get-Member -MemberType *Property |
    Select-Object -ExpandProperty Name |
    Where-Object { $_ -notin $default } |
    Sort-Object

# dump autostart programs
$keyNames | ForEach-Object {
    $values.$_
}
```

<!--本文国际来源：[Examining Object Properties Programmatically](http://community.idera.com/powershell/powertips/b/tips/posts/examining-object-properties-programmatically)-->
