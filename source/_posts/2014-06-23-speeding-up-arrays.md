---
layout: post
title: "PowerShell 技能连载 - 加速数组操作"
date: 2014-06-23 00:00:00
description: PowerTip of the Day - Speeding Up Arrays
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
当您频繁地向数组添加新元素时，您可能会遇到性能问题。以下是一个演示这个问题的反例，您应该**避免**这样使用：

    Measure-Command {
      $ar = @()
    
      for ($x=0; $x -lt 10000; $x++)
      {
        $ar += $x  
      }
    }

在循环中，数组用“+=”运算符不断地添加新元素。这将消耗许多时间，因为每次改变数组的大小时，PowerShell 都需要创建一个新的数组。

以下是一个快许多倍的实现方式——用 ArrayList，它专门为大小变化的情况设计：

    Measure-Command {
      $ar = New-Object -TypeName System.Collections.ArrayList
    
      for ($x=0; $x -lt 10000; $x++)
      {
        $ar.Add($x)
      }
    }
    
两段代码实现相同的效果，但第二段效率要高得多。

<!--more-->
本文国际来源：[Speeding Up Arrays](http://community.idera.com/powershell/powertips/b/tips/posts/speeding-up-arrays)
