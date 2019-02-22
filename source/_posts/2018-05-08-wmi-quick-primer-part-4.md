---
layout: post
date: 2018-05-08 00:00:00
title: "PowerShell 技能连载 - WMI 快速入门（第 4 部分）"
description: PowerTip of the Day - WMI Quick Primer (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，WMI 对象有许多包含重要信息的属性。这行代码将获取所有运行中的记事本实例的所有信息（请先运行记事本）：

```powershell
Get-WmiObject -Class Win32_Process -Filter 'Name LIKE "%notepad%"'
···

类似的，这行代码用 `Get-CimInstance` 获取相同的信息：

```powershell
Get-CimInstance -Class Win32_Process -Filter 'Name LIKE "%notepad%"'
```

有些时候，WMI 对象也包含方法。获取方法名最简单的方法是用 `Get-WmiObject`，然后将结果通过管道传送给 `Get-Member` 命令：

```powershell
PS> Get-WmiObject -Class Win32_Process -Filter 'Name LIKE "%notepad%"' | Get-Member -MemberType *method


    TypeName: System.Management.ManagementObject#root\cimv2\Win32_Process

Name                    MemberType   Definition
----                    ----------   ----------
AttachDebugger          Method       System.Management.ManagementBaseObject AttachDebugger()
GetAvailableVirtualSize Method       System.Management.ManagementBaseObject GetAvailableVirtualSize()
GetOwner                Method       System.Management.ManagementBaseObject GetOwner()
GetOwnerSid             Method       System.Management.ManagementBaseObject GetOwnerSid()
SetPriority             Method       System.Management.ManagementBaseObject SetPriority(System.Int32 Priority)
Terminate               Method       System.Management.ManagementBaseObject Terminate(System.UInt32 Reason)
ConvertFromDateTime     ScriptMethod System.Object ConvertFromDateTime();
ConvertToDateTime       ScriptMethod System.Object ConvertToDateTime();
```

要调用一个方法，例如获取一个进程的所有者时，`Get-WmiObject` 和 `Get-CimInstance` 之间有一个基本的区别：

当您通过 `Get-WmiObject` 获取对象时，对象的方法是返回对象的一部分：

```powershell
$notepads = Get-WmiObject -Class Win32_Process -Filter 'Name LIKE "%notepad%"'
$notepads | ForEach-Object {
    $notepads.GetOwner()
}
```

通过 `Get-CimInstance` 返回的对象不包含 WMI 方法。要调用 WMI 方法，您需要调用 `Invoke-CimMethod`：

```powershell
$notepads = Get-CimInstance -Class Win32_Process -Filter 'Name LIKE "%notepad%"'
$notepads |
    ForEach-Object {
    Invoke-CimMethod -InputObject $_ -MethodName "GetOwner"
    }
```

在以上的代码中，假设您移除 `GetOwner`，而是按下 `CTRL` + `SPACE` 键调出智能感知（或在简单 PowerShell 控制台中按 `TAB` 键），您可以获得所有可用的方法名称。如果一个方法需要参数，请使用 `-Arguments` 参数。

<!--本文国际来源：[WMI Quick Primer (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/wmi-quick-primer-part-4)-->
