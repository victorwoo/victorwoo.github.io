---
layout: post
date: 2015-02-26 12:00:00
title: "PowerShell 技能连载 - 简化命令提示符"
description: PowerTip of the Day - Shorten the Prompt
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 3.0 及以上版本_

缺省情况下，PowerShell 的命令提示符中包含了当前路径。当您以一个普通用户启动 PowerShell 时，当前路径就是您的用户路径。那是一个很长的路径，会占用命令行很多空间。

最有效最简单的方法是将当前目录改为根目录：

    PS C:\Users\Tobias\Documents> cd \

    PS C:\>

或者，可以调整 `prompt` 函数，使它在其它地方显示当前路径，例如在标题栏：

    function prompt
    {
      'PS> '
      $host.UI.RawUI.WindowTitle = Get-Location
    }

<!--本文国际来源：[Shorten the Prompt](http://community.idera.com/powershell/powertips/b/tips/posts/shorten-the-prompt)-->
