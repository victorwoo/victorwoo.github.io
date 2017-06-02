---
layout: post
date: 2015-08-19 11:00:00
title: "PowerShell 技能连载 - 隐藏变量内容"
description: PowerTip of the Day - Hiding Variable Content
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
当您覆盖某个对象的 `ToString()` 方法时，您就可以控制这个对象的显示方式。而这个对象的内容并不会被改变：

    $a = 123
    $a = $a | Add-Member -MemberType ScriptMethod -Name toString -Value { 'secret'} -Force -PassThru
    $a
    $a -eq 123
    $a.GetType().FullName

例如，当一个变量表示字节数的时候，您甚至可以在您的自定义的 `ToString()` 方法中获取原始的变量值，然后将它显示为 MB（兆字节）：

    $a = 2316782313
    $a = $a | Add-Member -MemberType ScriptMethod -Name toString -Value { [Math]::Round($this / 1MB,1) } -Force -PassThru
    $a
    $a -eq 123
    $a.GetType().FullName

<!--more-->
本文国际来源：[Hiding Variable Content](http://community.idera.com/powershell/powertips/b/tips/posts/hiding-variable-content)
