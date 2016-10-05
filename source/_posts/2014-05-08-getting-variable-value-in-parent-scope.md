layout: post
title: "PowerShell 技能连载 - 获取父作用域中的变量值"
date: 2014-05-08 00:00:00
description: PowerTip of the Day - Getting Variable Value in Parent Scope
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
如果您在一个函数中定义了变量，那么这些变量只在函数作用域内有效。要查看在外层作用域的变量值，请使用带 `-Scope` 参数的 `Get-Variable` 命令：

    $a = 1
    
    function test
    {
        $a = 2
        $parentVariable = Get-Variable -Name a -Scope 1
        $parentVariable.Value
    }
    
    test 

当脚本调用“test”函数时，函数定义了一个 `$a` 并且将它的值设为 2。在调用者作用域中，变量 `$a` 的值是 1。通过 `Get-Variable`，函数内可以得到外层作用域中的变量值。

<!--more-->
本文国际来源：[Getting Variable Value in Parent Scope](http://community.idera.com/powershell/powertips/b/tips/posts/getting-variable-value-in-parent-scope)
