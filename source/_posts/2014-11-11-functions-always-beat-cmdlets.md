layout: post
date: 2014-11-11 12:00:00
title: "PowerShell 技能连载 - 函数的优先级永远比 cmdlet 高"
description: PowerTip of the Day - Functions Always Beat Cmdlets
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
_适用于 PowerShell 所有版本_

函数的优先级永远比 cmdlet 高，所以如果两者名字相同，函数将会被执行。

这个函数将切实有效地改变 `Get-Process` 的行为：

    function Get-Process
    {
      'go away'
    } 

以下是意料之中的执行结果：

    PS> Get-Process
    go away 

甚至如果您指定了 cmdlet 的完整限定名，函数也可以优先执行：

    function Microsoft.PowerShell.Management\Get-Process
    {
      'go away'
    } 

执行结果：

    PS> Microsoft.PowerShell.Management\Get-Process -Id $pid 
    go away 

这也适用于别名。它们的优先级甚至比函数更高。

唯一能确保确实执行的是 cmdlet 的方法是直接存取模块，选择希望执行的 cmdlet，然后直接调用它：

    $module = Get-Module Microsoft.PowerShell.Management
    $cmdlet = $module.ExportedCmdlets['Get-Process'] 
    & $cmdlet   

或者，只需要用 `-noprofile` 参数启动一个新的 PowerShell，确保没有人能混进您的 PowerShell 环境即可。

<!--more-->
本文国际来源：[Functions Always Beat Cmdlets](http://community.idera.com/powershell/powertips/b/tips/posts/functions-always-beat-cmdlets)
