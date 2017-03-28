layout: post
date: 2015-05-14 11:00:00
title: "PowerShell 技能连载 - 使用闭包将变量保持在脚本块内"
description: PowerTip of the Day - Use Closures to Lock Variables to Script Blocks
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
当您使用脚本块中的变量时，运行脚本块时变量会被求值。

要将变量内容保持住，您可以创建一个新的“闭包”。当创建一个闭包之后，该脚本块持有该变量的值，该值为创建闭包时刻的值。

    $info = 1
    
    $code = 
    {
        $info
    }
    
    $code = $code.GetNewClosure()
    
    $info = 2
    
    & $code

如果不使用闭包，该脚本块将显示“2”，因为执行时 `$info` 的值为 2。通过闭包的作用，该脚本块内包含的值为创建闭包时赋予 `$info` 的值。

<!--more-->
本文国际来源：[Use Closures to Lock Variables to Script Blocks](http://community.idera.com/powershell/powertips/b/tips/posts/use-closures-to-lock-variables-to-script-blocks)
