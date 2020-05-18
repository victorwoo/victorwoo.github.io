---
layout: post
date: 2020-04-16 00:00:00
title: "PowerShell 技能连载 - 使用 WMI 实例路径（第 1 部分）"
description: PowerTip of the Day - Using WMI Instance Paths (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通常，最好远离旧的和过时的 `Get-WmiObject` 命令，而使用像 `Get-CimInstance` 这样的现代且更快的 CIM 命令。在大多数情况下，它们的效果几乎相同。

但是，在某些领域，新的 CIM 命令缺少信息。最重要的领域之一是 `Get-WmiObject` 返回的任何对象都可以使用的属性 "`__Path`"。使用 `Get-CimInstance` 时，会丢失这个属性。

此路径是 WMI 实例的唯一路径。请看一下——此命令列出了 `Win32_Share` 的所有实例，并将 WMI 路径返回给这些实例：

```powershell
PS> Get-WmiObject -Class Win32_Share | Select-Object -ExpandProperty __Path
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="ADMIN$"
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="C$"
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="HP Universal Printing PCL 6"
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="IPC$"
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="OKI PCL6 Class Driver 2"
\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="print$"
```

一旦知道实例的路径，就可以随时通过 `[wmi]` 类型轻松访问它：

```powershell
PS> [wmi]'\\DESKTOP-8DVNI43\root\cimv2:Win32_Share.Name="HP Universal Printing PCL 6"'

Name                        Path                      Description
----                        ----                      -----------
HP Universal Printing PCL 6 S/W Laser HP,LocalsplOnly S/W Laser HP
```

这非常有用，您可以使用现有的 WMI 路径或构造自己的 WMI 路径。例如，要访问其他服务器上的 `C$` 共享，只需查看路径即可立即确定需要更改的部分：

    \\SERVER12345\root\cimv2:Win32_Share.Name="C$"

`__Path` 属性也使类似这样的“WMI 浏览器”成为可能：

```powershell
# get all WMI instances
Get-WmiObject -Class CIM_LogicalDevice |
    # display propertes
    Select-Object -Property __Class, Name, Description, __Path |
    # let user select some
    Out-GridView -Title 'Select one or more (hold CTRL)' -PassThru |
    # retrieve the full selected instance by path
    ForEach-Object {
        [wmi]$_.__Path | Select-Object * | Out-Default
    }
```

<!--本文国际来源：[Using WMI Instance Paths (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-wmi-instance-paths-part-1)-->

