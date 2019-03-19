---
layout: post
date: 2015-03-26 11:00:00
title: "PowerShell 技能连载 - 只读及强类型变量"
description: PowerTip of the Day - Read-Only and Strongly Typed Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

要让 PowerShell 脚本更鲁棒，您可以针对脚本变量编写一系列约束条件。

这么做的效果是，PowerShell 将会为您监控这些约束条件，并且如果某些条件不满足，将抛出错误。

第一个约束条件是传入的数据类型必须和期望的相符。将数据类型放在方括号中，然后将它放在变量前面。这将会使一个通用类型的变量转换为一个强类型的变量。

    PS> $profile.AllUsersAllHosts
    C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1

    PS> [int]$ID = 12

    PS> $ID = 17

    PS> $ID = '19'

    PS> $ID = 'wrong'
    Cannot convert type "string"...

请看 `$ID` 变量是如何成为一个只能存储 Integer 数据的变量。望您将一个非 Integer 值，（例如 '19'）传入时，它将自动转换成 Integer 类型。如果无法转换（例如 'wrong'），PowerShell 将会抛出一个错误。

下一个约束条件是“只读”状态。如果您确信某个变量在脚本的某一部分中不可被更改，请将它保住为只读。任何试图改变该变量的操作都会触发一个 PowerShell 异常：

    PS> $a = 1

    PS> $a = 100

    PS> Set-Variable a -Option ReadOnly

    PS> $a
    100

    PS> $a = 200
    Cannot  overwrite variable.

    PS> Set-Variable a -Option None -Force

    PS> $a = 212

请注意写保护如何打开和关闭。要将写保护关闭，只需要将变量开关设为“`None`”，并且别忘了 `-Force` 开关。

如您所见，“`ReadOnly`”选项是一个软保护开关。您可以控制它开和关。在前一个技能中，您学到了“`Constant`”选项。`Constant` 的意思如它们的名字：常量。和“`ReadOnly`”不同，常量无法变回可写状态。

<!--本文国际来源：[Read-Only and Strongly Typed Variables](http://community.idera.com/powershell/powertips/b/tips/posts/read-only-and-strongly-typed-variables)-->
