layout: post
date: 2015-09-04 11:00:00
title: "PowerShell 技能连载 - 通用属性和可选的通用属性"
description: PowerTip of the Day - Common Parameters and Optional Common Parameters
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
cmdlet 和高级的 PowerShell 函数可以拥有自己的参数，但它们通常继承了通用的参数。

要查看通用参数的列表，请试试这段代码：

    PS> [System.Management.Automation.Cmdlet]::CommonParameters
    Verbose
    Debug
    ErrorAction
    WarningAction
    ErrorVariable
    WarningVariable
    OutVariable
    OutBuffer
    PipelineVariable

结果视 PowerShell 的版本可能会有不同。在 PowerShell 5.0 中，增加了两个通用的参数。

有些 cmdlet 可能有额外的通用参数。要列出这些参数，请试试这段代码：

    PS> [System.Management.Automation.Cmdlet]::OptionalCommonParameters
    WhatIf
    Confirm
    UseTransaction

<!--more-->
本文国际来源：[Common Parameters and Optional Common Parameters](http://powershell.com/cs/blogs/tips/archive/2015/09/04/common-parameters-and-optional-common-parameters.aspx)
