---
layout: post
date: 2018-07-05 00:00:00
title: "PowerShell 技能连载 - 使用缺省参数"
description: PowerTip of the Day - Using Default Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
If you find yourself always using the same parameter values over again, try using PowerShell default parameters. Here is how:
如果您常常反复使用相同的参数值，试着使用 PowerShell 的缺省参数。以下是实现方法：

```powershell
# hash table
# Key =
# Cmdlet:Parameter
# Value = 
# Default value for parameter
# * (Wildcard) can be used

$PSDefaultParameterValues = @{ 
'Stop-Process:ErrorAction' = 'SilentlyContinue' 
'*:ComputerName' = 'DC-01'
'Get-*:Path' = 'c:\windows'
}
```

在它的核心部分，有一个名为 `$PSDefaultParametersValues` 的哈希表。缺省情况下，这个变量不存在或者为空。如果您想将缺省参数复位为它们的缺省值，请运行以下代码：

```powershell     
PS> $PSDefaultParameterValues = $null 
```

哈希表的键是 cmdlet 名和参数值，通过 `***` 来分隔。支持通配符。哈希表的值是缺省参数值。

在上述例子中：

* `Stop-Process` 的 `-ErrorAction` 参数将总是使用 "SilentlyContinue" 值。
* 所有使用 `-ComputerName` 参数的 cmdlet 将使用 "DC-01"。
* 所有使用 `Get` 动词和 `-Path` 参数的 cmdlet 将默认使用 "C:\Windows" 值

缺省参数可能很方便，也可能很怪异。您不应在配置文件脚本中定义它们，因为您有可能忘了做过这件事，而下周会奇怪 cmdlet 执行的行为和预期不一致。

并且缺省参数只对 cmdlet 和高级函数有效。它们对简单函数是无效的：

```powershell
function Start-SimpleFunction
{
    param($ID=100)

    "ID = $ID"
}

function Start-AdvancedFunction
{
    [CmdletBinding()]
    param($ID=100)

    "ID = $ID"

}

$PSDefaultParameterValues = @{
    "Start-*Function:ID" = 12345
}
```

以下是执行结果：

```powershell
PS> Start-SimpleFunction
ID = 100

PS> Start-AdvancedFunction
ID = 12345

PS>
```

<!--本文国际来源：[Using Default Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/using-default-parameters1)-->
