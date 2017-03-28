layout: post
date: 2014-10-30 11:00:00
title: "PowerShell 技能连载 - 改变 PowerShell 的优先级"
description: PowerTip of the Day - Changing PowerShell Priority
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

也许您有时候希望 PowerShell 脚本在后台运行，例如复制文件时，但又不希望脚本抢占过多 CPU 或干预其它任务。

一种减慢 PowerShell 脚本运行速度的方法是降低它们的优先级。以下是一个实现该效果的函数：

    function Set-Priority
    {
        [CmdletBinding()]
        param
        (
            [Parameter(Mandatory=$true)]
            [System.Diagnostics.ProcessPriorityClass]
            $Priority
        )
        
        $process = Get-Process -Id $pid
        $process.PriorityClass = $Priority
    } 

要降低脚本的优先级，请这样调用：

    Set-Priority -Priority BelowNormal 

您可以稍后将优先级调回 Normal，甚至可以调高优先级使脚本获得更多资源执行。例如需要执行更重的任务，不过这会使 UI 响应性变得更差。

<!--more-->
本文国际来源：[Changing PowerShell Priority](http://community.idera.com/powershell/powertips/b/tips/posts/changing-powershell-priority)
