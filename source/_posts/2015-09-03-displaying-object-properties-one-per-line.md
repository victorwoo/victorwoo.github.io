layout: post
date: 2015-09-03 11:00:00
title: "PowerShell 技能连载 - 逐行显示对象的属性"
description: PowerTip of the Day - Displaying Object Properties One per Line
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
有些时候您可能需要查看某个对象中包含的数据。例如，如果您查询 PowerShell 的进程并将它显示在一个网格视图窗口中，您可以查看对象的内容：

    Get-Process -Id $pid | Out-GridView

但这样真的容易查看吗？这个对象显示在一行里，而且一个潜在的限制是网格视图窗口最多只能显示 30 列。由于所有信息都显示在一行里，您也无法搜索属性，因为总是整行被同时选中。

能否更友好地逐行显示对象属性呢？以下是实现方法：

    $object = Get-Process -Id $pid
    ($object | Get-Member -MemberType *Property).Name |
      ForEach-Object {
    
          New-Object PSObject -Property ([Ordered]@{Property=$_; Value=$object.$_ })
    
      } | Out-GridView

现在，每个属性各显示在一行上，可以尽可能多地显示，而且可以根据内容搜索某个特定的属性。

<!--more-->
本文国际来源：[Displaying Object Properties One per Line](http://powershell.com/cs/blogs/tips/archive/2015/09/03/displaying-object-properties-one-per-line.aspx)
