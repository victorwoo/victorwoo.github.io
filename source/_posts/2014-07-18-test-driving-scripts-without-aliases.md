---
layout: post
date: 2014-07-18 11:00:00
title: "PowerShell 技能连载 - 测试不带别名的脚本"
description: PowerTip of the Day - Test-Driving Scripts without Aliases
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
_适用于所有 PowerShell 版本_

别名在交互式 PowerShell 控制台中用起来很酷，但是不应在脚本中使用它们。在脚本中，请使用基础的命令（所以请使用 `Get-ChidItem` 而不是 `dir` 或 `ls`）。

要测试一个脚本，您可以删除所有的别名然后试试脚本是否任然能运行。以下是如何删除特定 PowerShell 会话中的所有别名的方法（它不会影响其它 PowerShell 会话，并且不会永久地删除内置的别名）：

    PS> Get-Alias | ForEach-Object { Remove-Item -Path ("Alias:\" + $_.Name) -Force }
    
    PS> dir
    dir : The term 'dir' is not recognized as the name of a cmdlet, function, script file, or operable
    program. Check the spelling of the name, or if a path was included, verify that the path is correct
    and try again.
    At line:1 char:1
    + dir
    + ~~~
        + CategoryInfo           : ObjectNotFound: (dir:String) [], CommandNotFoundException
        + FullyQualifiedErrorId : CommandNotFoundException
    
    PS> Get-Alias

如您所见，所有别名都清空了。现在如果一个脚本使用了别名，它将会抛出一个异常。而关闭并重启 PowerShell 之后，所有内置的别名都恢复了。

<!--more-->
本文国际来源：[Test-Driving Scripts without Aliases](http://community.idera.com/powershell/powertips/b/tips/posts/test-driving-scripts-without-aliases)
