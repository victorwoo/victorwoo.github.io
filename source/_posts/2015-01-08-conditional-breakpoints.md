---
layout: post
date: 2015-01-08 12:00:00
title: "PowerShell 技能连载 - 条件断点"
description: PowerTip of the Day - Conditional Breakpoints
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
_适用于 PowerShell 3.0 及以上版本_

PowerShell ISE 只支持行断点：它们的作用是当调试器命中指定的行时，使代码暂停执行。您可以在 PowerShell ISE 中按 `F9` 来切换行断点。只需要保证脚本已经保存。未保存的脚本（“无标题”）中的断点是无效的。

一个更复杂的做法是使用动态（或称为“条件”）断点。它们并不是关联于某一行上而是和某一种情况有关联。

要在某个变量被赋予一个新值的时候使脚本停下来，请使用这段示例代码（请先保存后执行）：

    $bp = Set-PSBreakpoint -Variable a -Mode Write -Script $psise.CurrentFile.FullPath
    
    $a = 1
    $a
    
    $a
    
    $a = 200
    $a
    
    Remove-PSBreakpoint -Breakpoint $bp

当您运行它时，PowerShell 调试器将会在 `$a` 被赋予一个新值的时候暂停脚本执行。

您甚至可以为它绑定一个更复杂的条件。这个例子将只会在对 `$a` 赋予一个大于 100 的整数值时才使脚本暂停。

    $Condition = { if ($a -is [Int] -and $a -gt 100) { break }  }
    $bp = Set-PSBreakpoint -Variable a -Mode Write -Script $psise.CurrentFile.FullPath -Action $Condition
    
    $a = 1
    $a
    
    $a
    
    $a = 200
    $a
    
    Remove-PSBreakpoint -Breakpoint $bp

<!--more-->
本文国际来源：[Conditional Breakpoints](http://community.idera.com/powershell/powertips/b/tips/posts/conditional-breakpoints)
