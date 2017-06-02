---
layout: post
title: "PowerShell 技能连载 - 用 Splatting 技术提交参数"
date: 2014-06-03 00:00:00
description: PowerTip of the Day - Submitting Parameters through Splatting
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
Splatting 是 PowerShell 3.0 引入的概念，但是许多用户还没有听说这个概念。这是一种以可编程的方式将参数传给 cmdlet 的技术。请看：

    $infos = @{}
    $infos.Path = 'c:\Windows'
    $infos.Recurse = $true
    $infos.Filter = '*.log'
    $infos.ErrorAction = 'SilentlyContinue'
    $infos.Remove('Recurse')
    
    dir @infos 

这个例子定义了一个包含键值对的哈希表。每个键对应 dir 命令中的一个参数，并且每个值作为实参传递给对应的形参。

当您的代码需要决定哪些参数需要传给 cmdlet 时，Splatting 十分有用。您的代码可以只需要维护一个哈希表，然后选择性地将它传给 cmdlet。

<!--more-->
本文国际来源：[Submitting Parameters through Splatting](http://community.idera.com/powershell/powertips/b/tips/posts/submitting-parameters-through-splatting)
