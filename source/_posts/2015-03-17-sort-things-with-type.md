layout: post
date: 2015-03-17 11:00:00
title: "PowerShell 技能连载 - 根据类型对数据排序"
description: PowerTip of the Day - Sort Things with Type
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
_适用于 PowerShell 所有版本_

`Sort-Object` 是一站式的排序解决方案。如果要对简单数据类型排序，只需要将它通过管道传递给 `Sort-Object`。如果要对复杂数据类型排序，则需要指定排序所使用的属性：

    # sorting primitive data
    1,5,2,1,6,3,12,6 | Sort-Object -Unique
    
    # sorting object data
    Get-ChildItem -Path c:\windows | Sort-Object –Property name

由于对象的天生原因，PowerShell 自动选择排序的算法。但如果您需要更多的控制呢？

只需要传入一个代码块。在代码块中，`$_` 代表需要排序的对象。您可以将它转型为任何期望的类型：

    # sorting string as numbers
    '1','5','3a','12','6' | Sort-Object -Property { $_ -as [int]  }
    
    # sorting IPv4 addresses as versions
    '1.2.3.4', '10.1.2.3', '100.4.2.1', '2.3.4.5', '9.10.11.12' | 
      Sort-Object -Property { [version] $_ }

<!--more-->
本文国际来源：[Sort Things with Type](http://powershell.com/cs/blogs/tips/archive/2015/03/17/sort-things-with-type.aspx)
