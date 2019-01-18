---
layout: post
date: 2019-01-03 00:00:00
title: "PowerShell 技能连载 - 列出网络驱动器"
description: PowerTip of the Day - Listing Network Drives
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
有着许多方法可以创建网络驱动器的列表。其中一个需要调用 COM 接口。这个接口也可以通过 VBScript 调用。我们将利用它演示一个特殊的 PowerShell 技术。

要列出所有网络驱动器，只需要运行这几行代码：

```powershell
$obj = New-Object -ComObject WScript.Network
$obj.EnumNetworkDrives()
```

结果类似这样：

```powershell
PS> $obj.EnumNetworkDrives()

X:
\\storage4\data
Z:
\\127.0.0.1\c$
```

这个方法对每个网络驱动器返回两个字符串：挂载的驱动器号，以及原始 URL。要将它转为有用的东西，您需要创建一个循环，每次迭代返回两个元素。

以下是一个聪明的方法来实现这个目标：

```powershell
$obj = New-Object -ComObject WScript.Network
$result = $obj.EnumNetworkDrives()

Foreach ($entry in $result)
{
    $letter = $entry
    $null = $foreach.MoveNext()
    $path = $foreach.Current


    [PSCustomObject]@{
        DriveLetter = $letter
        UNCPath = $path
    }
}
```

在 `foreach` 循环中，有一个很少人知道的自动变量，名为 `$foreach`，它控制着迭代。当您调用 `MoveNext()` 方法时，它对整个集合迭代，移动到下一个元素。通过 `Current` 属性，可以读取到迭代器的当前值。

通过这种方法，循环每次处理两个元素，而不仅仅是一个。两个元素合并为一个自定义对象。结果看起来类似这样：

    DriveLetter UNCPath
    ----------- -------
    X:          \\storage4\data
    Z:          \\127.0.0.1\c$

<!--more-->
本文国际来源：[Listing Network Drives](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-network-drives)
