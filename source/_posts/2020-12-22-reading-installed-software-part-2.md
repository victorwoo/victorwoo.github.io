---
layout: post
date: 2020-12-22 00:00:00
title: "PowerShell 技能连载 - 读取已安装的软件（第 2 部分）"
description: PowerTip of the Day - Reading Installed Software (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们演示了 `Get-ItemProperty` 强大的功能，并且您可以通过读取多个注册表位置而仅用一行代码来创建整个软件清单。

今天，让我们在软件清单中添加两个重要的信息：范围（是为每个用户安装的软件还是为所有用户安装的软件？）和体系结构（x86或x64）。

每个信息都无法在注册表键值中找到，而是通过确定信息在注册表中的存储位置来找到。这是 `Get-ItemProperty` 提供的另一个巨大好处：它不仅返回给定注册表项的注册表值。它还添加了许多属性，例如 `PSDrive`（注册表配置单元）和 `PSParentPath`（正在读取注册表项的路径）。

以下是根据发现信息的地方将范围和体系结构信息添加到软件清单的解决方案：

```powershell
# Registry locations for installed software
$paths =
    # all users x64
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    # all users x86
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    # current user x64
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    # current user x86
    'HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

# calculated properties

# AllUsers oder CurrentUser?
$user = @{
    Name = 'Scope'
    Expression = {
        if ($_.PSDrive -like 'HKLM')
        {
            'AllUsers'
        }
        else
        {
            'CurrentUser'
        }
    }
}

# 32- or 64-Bit?
$architecture = @{
    Name = 'Architecture'
    Expression = {
        if ($_.PSParentPath -like '*\WOW6432Node\*')
        {
            'x86'
        }
        else
        {
            'x64'
        }
    }
}
Get-ItemProperty -ErrorAction Ignore -Path $paths |
    # eliminate reg keys with empty DisplayName
    Where-Object DisplayName |
    # select desired properties and add calculated properties
    Select-Object -Property DisplayName, DisplayVersion, $user, $architecture
```

<!--本文国际来源：[Reading Installed Software (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-installed-software-part-2)-->

