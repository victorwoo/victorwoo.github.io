---
layout: post
date: 2015-01-30 12:00:00
title: "PowerShell 技能连载 - 自动展开和内存消耗"
description: PowerTip of the Day - Automatic Unrolling and Memory Consumption
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

在 PowerShell 3.0 中，增加了一个称为“自动回滚”的特性。通过这个特性，您可以这样书写代码：

    (Get-ChildItem -Path $env:windir\system32 -Filter *.dll).VersionInfo  

这行代码查找 System32 子文件夹下的所有 DLL 文件并且对它们进行迭代，对每个文件返回其 `VersionInfo` 属性（实际上是 DLL 版本）。在使用自动展开功能之前，您需要手工编写循环语句：

    Get-ChildItem -Path $env:windir\system32 -Filter *.dll | ForEach-Object { $_.VersionInfo } 

当您运行以上两段代码时，它们返回完全相同的结果。然而，您将立刻发现自动展开特性所带来的代价：它消耗了更多的时间才返回结果。第一行结果出来时可能要消耗 10 秒之多的时间，而“传统”的方法几乎是连续地返回信息。

总体消耗的时间是差不多的。实际上，自动展开特性等价的代码如下：

    $data = Get-ChildItem -Path $env:windir\system32 -Filter *.dll
    Foreach ($element in $data) { $element.VersionInfo } 

自动展开代码更直观，更容易书写；手写循环兼容性更好，更快输出结果。

<!--more-->
本文国际来源：[Automatic Unrolling and Memory Consumption](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-unrolling-and-memory-consumption)
