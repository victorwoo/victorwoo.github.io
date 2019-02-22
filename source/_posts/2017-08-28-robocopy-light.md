---
layout: post
date: 2017-08-28 00:00:00
title: "PowerShell 技能连载 - 轻量级 Robocopy"
description: PowerTip of the Day - Robocopy Light
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Robocopy.exe` 是一个非常有用并且功能多样的内置命令，它可以高效地将文件从一个地方复制到另一个地方。不幸的是，该命令有很多选项和开关，使得它很难掌握。

如果您只是希望将文件从 A 处拷贝到 B 处，以下是将 robocopy 封装并将这个怪兽转化为易用的复制命令的函数：

```powershell
function Copy-FileWithRobocopy
{
    param
    (
        [Parameter(Mandatory)]
        $Source,

        [Parameter(Mandatory)]
        $Destination,

        $Filter = '*'
    )

    robocopy.exe $Source $Destination $Filter /S /R:0
}
```

以下是如何使用新命令的方法：下面这行代码将所有 .log 文件从 Windows 文件夹复制到 `c:\logs` 文件夹：

```powershell
PS> Copy-FileWithRobocopy -Source $env:windir -Destination c:\logs -Filter *.log
```

<!--本文国际来源：[Robocopy Light](http://community.idera.com/powershell/powertips/b/tips/posts/robocopy-light)-->
