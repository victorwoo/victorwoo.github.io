---
layout: post
date: 2018-01-01 00:00:00
title: "PowerShell 技能连载 - 删除环境变量"
description: PowerTip of the Day - Deleting Environment Variables
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
在前一个技能中我们解释了如何在所有可用的范围内设置环境变量的方法。但是如何移除环境变量呢？

巧合地，您可以用完全相同的方法做这件事情，只需要将一个空字符串赋给该变量。然而，前一个技能中的函数中的 `-VariableValue` 参数不能接受空字符串：

```powershell
function Set-EnvironmentVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)][String]
        $VariableName,

        [Parameter(Mandatory)][String]
        $VariableValue,

        [Parameter(Mandatory)][EnvironmentVariableTarget]
        $Target
    )

    [Environment]::SetEnvironmentVariable($VariableName, $VariableValue, $Target)
}
```

当您尝试着赋值空字符串时，将会收到这样的提示：

```powershell
PS C:\>  Set-EnvironmentVariable -VariableName test -VariableValue "" -Target  User
Set-EnvironmentVariable  : Cannot bind Argument to Parameter "VariableValue" because it is an  empty string.
...
```

这是因为当您将一个参数声明为 "Mandatory"，PowerShell 缺省情况下将拒绝空字符串和 null 值。

您可以将 `VariableValue` 参数设为可选的，但是这样当您调用该函数不传该参数时，PowerShell 将不再提示。如何使一个必选参数能接受 null 和空字符串呢？

只要稍微改一下，加上 `[AllowNull()]` 和/或 `[AllowEmptyString()]` 以上函数就可以支持删除环境变量：

```powershell
function Set-EnvironmentVariable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)][String]
        $VariableName,

        [Parameter(Mandatory)][String]
        [AllowEmptyString()]
        $VariableValue,

        [Parameter(Mandatory)][EnvironmentVariableTarget]
        $Target
    )

    [Environment]::SetEnvironmentVariable($VariableName, $VariableValue, $Target)
}
```

以下是删除 "Test" 环境变量的方法：

```powershell
PS C:\> Set-EnvironmentVariable -VariableName test -VariableValue "" -Target User
```

<!--more-->
本文国际来源：[Deleting Environment Variables](http://community.idera.com/powershell/powertips/b/tips/posts/deleting-environment-variables)
