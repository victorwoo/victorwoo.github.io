---
layout: post
date: 2015-08-17 11:00:00
title: "PowerShell 技能连载 - 向原始数据类型增加额外信息"
description: PowerTip of the Day - Appending Extra Information to Primitive Data Types
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
也许您希望对一个变量做标记并提供一些额外信息。在 PowerShell 中，可以使用 `Add-Member` 来向一个变量附加 NoteProperties 或 ScriptProperties。

一个 NoteProperty 包含一些静态信息，而当我们获取一个 ScriptProperty 的值时，将会运行一段代码。

请看如何对一个简单的字符串做操作：

    $a = "some text"
    
    $a = $a | Add-Member -MemberType NoteProperty -Name Origin -Value $env:computername -PassThru
    $a = $a | Add-Member -MemberType ScriptProperty -Name Time -Value { Get-Date } -PassThru
    
    $a
    $a.Origin
    $a.Time

<!--more-->
本文国际来源：[Appending Extra Information to Primitive Data Types](http://community.idera.com/powershell/powertips/b/tips/posts/appending-extra-information-to-primitive-data-types)
