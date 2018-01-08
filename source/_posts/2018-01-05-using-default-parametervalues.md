---
layout: post
date: 2018-01-05 00:00:00
title: "PowerShell 技能连载 - 使用缺省参数值"
description: PowerTip of the Day - Using Default Parameter Values
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
You may have heard about PowerShell default parameter values and $PSDefaultParameterValues. When you assign a hash table to this special variable, the key defines the commands and parameters affected, and the value defines your new default value.
您可能听说过 PowerShell 的缺省参数值和 `$PSDefaultParameterValues`。当您将一个哈希表赋给这个特殊的变量，则哈希表的键定义了命令和影响的参数，而值定对应新的缺省值。

请看这个例子：

```powershell
$PSDefaultParameterValues = @{
    '*:ComputerName' = 'testserver1'
}
```

这将会把所有命令 (`*`) 的 `-ComputerName` 设置为新的缺省值 "testserver1"。当您调用一个命令，且满足以下两个条件 (a) 有一个名为 `ComputerName` 的参数 (b) 没有显式地赋值给这个参数时，将会使用缺省值。

这对 PowerShell 函数也有效，然而只对 "Advanced Functions" 有效，对 "Simple Functions" 无效。

要验证区别，请按上述介绍定义 `$PSDefaultParameterValues`，然后运行这段代码：

```powershell
function testSimple
{ 
    param($Computername) 
    
    "Result Simple: $Computername" 
}

function testAdvanced
{ 
    [CmdletBinding()]
    param($Computername) 
    
    "Result Advanced: $Computername" 
}


testSimple

testAdvanced
```

如您所见，只有 testAdvanced 函数应用了缺省参数。"Advanced Functions" 至少要定义一个参数属性，例如 `[CmdletBinding()]` 或 `[Parameter(Mandatory)]`。

<!--more-->
本文国际来源：[Using Default Parameter Values](http://community.idera.com/powershell/powertips/b/tips/posts/using-default-parametervalues)
