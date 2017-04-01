layout: post
date: 2014-08-04 11:00:00
title: "PowerShell 技能连载 - 请注意 UNC 路径！"
description: PowerTip of the Day - Watch Out With UNC Paths!
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

许多 cmdlet 可以处理 UNC 路径，但是使用 UNC 路径会导致很多古怪的情况。请看以下：

    PS> Test-Path -Path \\127.0.0.1\c$
    True

这段代码返回了 `true`，该 UNC 路径存在。现在将当前驱动器变为一个非文件系统驱动器，然后再次实验：

    PS> cd hkcu:\
    
    PS> Test-Path -Path \\127.0.0.1\c$
    False 

同样的路径现在返回了 `false`。这是因为 UNC 路径并不包含驱动器号，而 PowerShell 需要驱动器号来指定正确的提供器。如果一个路径不包含驱动器号，那么 PowerShell 假设使用当前驱动器的提供器。所以如果您将当前的目录改为注册表，PowerShell 尝试在那儿查找 UNC 路径，那么就会失败。

更糟糕的是，出于某些未知的原因，但您用 `net use` 来映射驱动器时，PowerShell 在使用 cmdlet 来访问驱动器时可能会也可能不会产生混淆。

解决方案十分简单：当您用 cmdlet 访问 UNC 时，始终在 UNC 路径前面加上正确的提供器名称。这将消除该问题：

    PS> Test-Path -Path FileSystem::\\127.0.0.1\c$
    True
    
    PS> cd hkcu:\
    
    PS> Test-Path -Path \\127.0.0.1\c$
    False
    
    PS> Test-Path -Path FileSystem::\\127.0.0.1\c$
    True
    

如果您遇到了 `net use` 产生的问题，也可以使用同样的办法，在路径前面加上 `“FileSystem::`。该问题可以立刻得到解决。

<!--more-->
本文国际来源：[Watch Out With UNC Paths!](http://community.idera.com/powershell/powertips/b/tips/posts/watch-out-with-unc-paths)
