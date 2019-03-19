---
layout: post
date: 2018-07-09 00:00:00
title: "PowerShell 技能连载 - 从函数中返回富对象（第 1 部分）"
description: PowerTip of the Day - Returning Rich Objects from Functions (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果一个 PowerShell 函数需要返回多于一类信息，请确保将这些信息集中到一个富对象中。最简单的实现方式是创建一个类似 `[PSCustomObject]@{}` 这样的自定义对象：

```powershell
function Get-TestData
{
    # if a function is to return more than one information kind,
    # wrap it in a custom object

    [PSCustomObject]@{
        # wrap anything you'd like to return
        ID = 1
        Random = Get-Random
        Date = Get-Date
        Text = 'Hallo'
        BIOS = Get-WmiObject -Class Win32_BIOS
        User = $env:username
    }
}
```

自定义对象的核心是一个哈希表：每个哈希表键将会转换为一个属性。这个方式的好处是您可以使用哈希表中的变量甚至命令，所以这样要收集您想返回的所有信息，将它合并为一个自描述的对象很容易：

```powershell
PS> Get-TestData


ID     : 1
Random : 1794057589
Date   : 25.05.2018 13:06:57
Text   : Hallo
BIOS   : \\DESKTOP-7AAMJLF\root\cimv2:Win32_BIOS.Name="1.6.1",SoftwareElementID="1.6.1",SoftwareElementState=3,TargetOperatingSys
            tem=0,Version="DELL   - 1072009"
User   : tobwe
```

<!--本文国际来源：[Returning Rich Objects from Functions (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/returning-rich-objects-from-functions-part-1)-->
