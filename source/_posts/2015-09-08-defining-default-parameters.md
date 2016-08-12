layout: post
date: 2015-09-08 11:00:00
title: "PowerShell 技能连载 - 定义缺省参数"
description: PowerTip of the Day - Defining Default Parameters
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
PowerShell 可以为任意参数定义缺省值，所以如果您总是需要传同一个缺省值给 `Get-ChildItem` 的 `-Path` 参数，那么可以这么做：

    PS> $PSDefaultParameterValues['Get-ChildItem:Path'] = 'C:\$Recycle.Bin'

当您运行 `Get-ChildItem`（或它的别名，例如 `dir`），并且没有传入 `-Path` 参数时，PowerShell 总是会使用 `$PSDefaultParameterValues` 变量中定义的值。

您也可以使用通配符。例如，如果您希望对所有 AD 命令的 `-Server` 参数设置缺省值，请试试这段代码：

    PS> $PSDefaultParameterValues['*-AD*:Server'] = 'dc-01'


`$PSDefaultParameterValues` 实际上是一个哈希表，所以您可以覆盖缺省值，或将当前定义的所有缺省值导出成列表：

    Name                           Value                                                                 
    ----                           -----                                                                 
    *-AD*:Server                   dc-01                                                                 
    Get-ChildItem:Path             C:\$Recycle.Bin

要清空所有缺省参数，请清除哈希表：

    PS> $PSDefaultParameterValues.Clear()

<!--more-->
本文国际来源：[Defining Default Parameters](http://powershell.com/cs/blogs/tips/archive/2015/09/08/defining-default-parameters.aspx)
