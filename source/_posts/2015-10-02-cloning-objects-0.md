layout: post
date: 2015-10-02 11:00:00
title: "PowerShell 技能连载 - 复制对象"
description: PowerTip of the Day - Cloning Objects
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
在前一个技能中我们演示了 PowerShell 是通过引用存储对象的。如果您想创建一个浮板，您可能需要手工复制对象的所有属性。

以下是一个简单的克隆对象的方法：

    $object1 = @{Name='Weltner'; ID=12 }
    $object2 = @{Name='Frank'; ID=99 }
    
    
    $a = $object1, $object2
    
    # clone entire object by serializing it back and forth:
    $b = $a | ConvertTo-Json -Depth 99 | ConvertFrom-Json
    
    $b[0].Name = 'changed'
    $b[0].Name
    $a[0].Name

不过，请注意序列化的过程可能会改变复制的对象类型。

    PS C:\> $a[0].GetType().FullName
    System.Collections.Hashtable
    
    PS C:\> $b[0].GetType().FullName
    System.Management.Automation.PSCustomObject
    
    PS C:\>

<!--more-->
本文国际来源：[Cloning Objects](http://community.idera.com/powershell/powertips/b/tips/posts/cloning-objects-0)
