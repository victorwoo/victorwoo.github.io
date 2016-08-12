layout: post
date: 2015-10-16 11:00:00
title: "PowerShell 技能连载 - 简化参数属性"
description: PowerTip of the Day - Simplify Parameter Attributes
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
如果您的系统运行的是 PowerShell 3.0 及以上版本，您可以简化函数参数的属性。布尔属性的缺省值都为 `$true`，所以这在 PowerShell 2.0 中是缺省代码：

    function Get-Sample
    {
      Param
      (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Name
      )
    }

从 PowerShell 3.0 开始，它浓缩成：

    function Get-Sample
    {
      Param
      (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $Name
      )
    }

新的代码更精炼，但是无法在 PowerShell 2.0 中运行。

<!--more-->
本文国际来源：[Simplify Parameter Attributes](http://powershell.com/cs/blogs/tips/archive/2015/10/16/simplify-parameter-attributes.aspx)
