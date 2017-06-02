---
layout: post
date: 2015-05-12 11:00:00
title: "PowerShell 技能连载 - 互斥参数 (1)"
description: PowerTip of the Day - Mutual Exclusive Parameters
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
有些时候，PowerShell 的函数参数必须是互斥的：用户只能用这类参数多个中的一个，而不能同时使用。

要创建互斥参数，请将他们指定到不同的参数集中，并且确保定义了一个缺省的参数集（当 PowerShell 无法自动选择正确的参数集时使用）：

    function Test-ParameterSet
    {
      [CmdletBinding(DefaultParameterSetName='number')]
      param
      (
        [int]
        [Parameter(ParameterSetName='number', Position=0)]
        $id,
    
        [string]
        [Parameter(ParameterSetName='text', Position=0)]
        $name
      )
    
      $PSCmdlet.ParameterSetName
      $PSBoundParameters
    }

`Test-ParameterSet` 函数有两个参数：`-id` 和 `-name`。用户只能指定一个参数，而不能同时指定两个参数。这个例子也演示了如何知道用户选择了哪个参数集。

<!--more-->
本文国际来源：[Mutual Exclusive Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/mutual-exclusive-parameters)
