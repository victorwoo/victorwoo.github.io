layout: post
date: 2014-10-22 11:00:00
title: "PowerShell 技能连载 - 伪造对象类型"
description: PowerTip of the Day - Faking Object Type
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
_适用于 PowerShell 3.0 及以上版本_

PowerShell 内部的类型扩展系统的作用是负责将对象转换为文本。它的实现方法是通过查询一个名为“PSTypeName”的属性。您可以为自定义的对象添加这个属性来模拟其它对象类型并使 ETS 用相同方式显示该对象：

    $object = [PSCustomObject]@{
      ProcessName = 'notepad'
      ID = -1
      PSTypeName = 'System.Diagnostics.Process'
    } 

The object pretends to be a process object, and ETS will format it accordingly:

    PS> $object
    
    Handles  NPM(K)    PM(K)      WS(K) VM(M)   CPU(s)     Id ProcessName          
    -------  ------    -----      ----- -----   ------     -- -----------          
                  0        0          0     0              -1 notepad              
    
    
    
    PS>

<!--more-->
本文国际来源：[Faking Object Type](http://community.idera.com/powershell/powertips/b/tips/posts/faking-object-type)
