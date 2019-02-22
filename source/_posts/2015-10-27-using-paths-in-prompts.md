---
layout: post
date: 2015-10-27 11:00:00
title: "PowerShell 技能连载 - 在命令提示符中显示路径"
description: PowerTip of the Day - Using Paths in Prompts
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
缺省的 PowerShell 提示符显示当前的位置。当您在很深的嵌套文件夹中时，这将占用您的输入空间，而且会导致需要滚动才能看清。

有很多方法可以解决这个问题。以下是针对这个题的两个 prompt 的替代函数。

第一个是保持在当前提示符中显示当前路径，但实际的输入是在下面一行，所以您的输入总是可见。

    function prompt
    {
      Write-Host("PS: $pwd>")
    }

另一种方式是在窗体的标题栏显示当前的路径：

    function prompt
    {
      $host.UI.RawUI.WindowTitle = Get-Location
      'PS> '
    }

如果您想用这些方法，请将它们放在自启动脚本中（缺省情况下可能不存在）。它的路径可以通过 `$profile` 变量找到。

<!--本文国际来源：[Using Paths in Prompts](http://community.idera.com/powershell/powertips/b/tips/posts/using-paths-in-prompts)-->
