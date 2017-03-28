layout: post
title: "PowerShell 技能连载 - PowerShell 不支持 JSON 数据类型"
date: 2014-05-12 00:00:00
description: PowerTip of the Day - PowerShell does not support JSON Data Types
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
缺省情况下，从 JSON 创建的对象使用 String 作为数据的类型：

    $json = @"
    {
        "Name": "Weltner",
        "ID" : "123"
     }
    "@
    
    $info = ConvertFrom-Json -InputObject $json
    $info.Name
    $info.ID
    
![](/img/2014-05-12-powershell-does-not-support-json-data-types-001.png)

但是，JSON 不支持数据类型，虽然 JSON 数据类型并不等价于 .NET 数据类型。请注意在以下代码中，“ID”被定义成“数字”型，并且它被赋予一个数值型的值，而不需要用双引号引起来。

    $json = @"
    {
        "Name": "Weltner",
        number: "ID" : 123
     }
    "@
    
    $info = ConvertFrom-Json -InputObject $json
    $info.Name
    $info.ID
    
    
然而，当使用 `ConvertFrom-Json` 时，我们发现 PowerShell 并没有关心数据类型定义。它总是将值转换为 String 数据。

![](/img/2014-05-12-powershell-does-not-support-json-data-types-002.png)

<!--more-->

本文国际来源：[PowerShell does not support JSON Data Types](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-does-not-support-json-data-types)
