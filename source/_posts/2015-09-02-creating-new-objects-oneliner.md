---
layout: post
date: 2015-09-01 23:00:00
title: "PowerShell 技能连载 - 只用一行代码创建新对象"
description: PowerTip of the Day - Creating New Objects - Oneliner
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候您可能需要创建自己的对象来存储一系列信息。以下这行简洁的单行代码演示了如何快速创建新的对象：

    #requires -Version 3
    
    $Info = 'Test'
    $SomeOtherInfo = 12
    
    New-Object PSObject -Property ([Ordered]@{Location=$Info; Remark=$SomeOtherInfo })

这段代码的执行后将创建包含 Location 和 Remark 两个属性的新对象。只需要重命名哈希表中的键名，即可改变对象的属性名。

    Location Remark
    -------- ------
    Test         12

请注意 `[Ordered]` 是 PowerShell 3.0 引入的，能够创建有序的哈希表。在 PowerShell 2.0 中，可以使用不带 `[ordered]` 的代码。不带它会导致新对象中的属性顺序是随机的。

<!--本文国际来源：[Creating New Objects - Oneliner](http://community.idera.com/powershell/powertips/b/tips/posts/creating-new-objects-oneliner)-->
