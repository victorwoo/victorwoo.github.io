---
layout: post
date: 2018-11-06 00:00:00
title: "PowerShell 技能连载 - 隐藏通用属性"
description: PowerTip of the Day - Hiding Common Parameters
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
在前一个技能中我们解释了如何在 IntelliSense 中隐藏参数。今天我们想向您介绍一个很酷的副作用！

PowerShell 支持两种类型的函数：简单函数和高级函数。一个简单的函数只暴露了您定义的参数。高级函数还加入了所有常见的参数。以下是两个示例函数：

```powershell
function Simple
{
    param
    (
        $Name
    )
}

function Advanced
{
    param
    (
        [Parameter(Mandatory)]
        $Name
    )
}
```

当您在编辑器中通过 IntelliSense 调用 `Simple` 函数，您只能见到 `-Name` 参数。当您调用 `Advanced` 函数时，还能看到一系列常见的参数，这些参数总是出现。

当您使用一个属性（属性的模式为 `[Name(Value)]`），PowerShell 将创建一个高级函数，并且无法排除通用参数。那么如何既保留高级函数的优点（例如必选参数）但只向用户显示自己的参数呢？

以下是一个秘籍。请对比以下两个函数：

```powershell
function Advanced
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,
        
        [int]
        $Id,
        
        [switch]
        $Force
    )
}

function AdvancedWithoutCommon
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,
        
        [int]
        $Id,
        
        [switch]
        $Force,
        
        # add a dummy "DontShow" parameter
        [Parameter(DontShow)]
        $Anything
    )
}
```

当调用 "`Advanced`" 函数时，将显示自定义的参数以及通用参数。当对 "`AdvancedWithoutCommon`" 做相同的事时，只会见到自定义的参数但保留高级函数的功能，例如 `-Name` 参数仍然是必选的。

这种效果是通过添加一个或多个隐藏参数实现的。隐藏参数是从 PowerShell 5 开始引入的，用于加速类方法（禁止显示隐藏属性）。由于类成员不显示通用参数，所以属性值 "`DontShow`" 不仅从 IntelliSense 中隐藏特定的成员，而且隐藏所有通用参数。

这恰好导致另一个有趣的结果：虽然通用参数现在从 IntelliSense 中隐藏，但他们仍然存在并且可使用：

```powershell
function Test
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,
        
        # add a dummy "DontShow" parameter
        [Parameter(DontShow)]
        $Anything
    )
    
    Write-Verbose "Hello $Name"
}


    
PS> Test -Name tom

PS> Test -Name tom -Verbose
VERBOSE:  Hello tom

PS>
```

<!--more-->
本文国际来源：[Hiding Common Parameters](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hiding-common-parameters)
