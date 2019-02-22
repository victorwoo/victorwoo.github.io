---
layout: post
date: 2015-10-01 11:00:00
title: "PowerShell 技能连载 - 复制数组（第 2 部分）"
description: PowerTip of the Day - Copying Arrays (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们解释了如何用 `Clone()` 方法安全地“克隆”一个数组。这将把一个数组的内容复制到一个新的数组。

然而，如果数组的元素是对象（不是数字或字符串等原始数据类型），数组存储了这些对象的内存地址，所以克隆方法虽然创建了一个新的数组，但是新的数组仍然引用了相同对象。请看：

    $object1 = @{Name='Weltner'; ID=12 }
    $object2 = @{Name='Frank'; ID=99 }
    
    
    $a = $object1, $object2
    $b = $a.Clone()
    $b[0].Name = 'changed'
    $b[0].Name
    $a[0].Name

虽然您克隆了数组 `$a`，但是新的数组 `$b` 仍然引用了相同的对象，对对象的更改会同时影响两个数组。只有对数组内容的更改是独立的：

    $object1 = @{Name='Weltner'; ID=12 }
    $object2 = @{Name='Frank'; ID=99 }
    
    
    $a = $object1, $object2
    $b = $a.Clone()
    $b[0] = 'deleted'
    $b[0]
    $a[0]

<!--本文国际来源：[Copying Arrays (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/copying-arrays-part-2)-->
