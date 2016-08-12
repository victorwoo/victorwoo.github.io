layout: post
title: "PowerShell 技能连载 - 使用配置脚本"
date: 2014-06-13 00:00:00
description: PowerTip of the Day - Using Profile Scripts
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
您可能知道 PowerShell 支持配置脚本。只需要确保 `$profile` 所指定的文件存在即可。它是一个普通的脚本，每当 PowerShell 宿主启动的时候都会执行。

所以可以很方便地配置 PowerShell 环境、加载模块、增加 snap-in，以及做其它调整。这段代码将缩短您的 PowerShell 提示符，并且在标题栏显示当前路径：

    function prompt
    {
      'PS> '
      $host.UI.RawUI.WindowTitle = Get-Location
    } 

请注意 `$profile` 指定的配置脚本是和宿主有关的。每个宿主有独立的配置脚本（包括 PowerShell 控制台、ISE 编辑器以及所有的 PowerShell 宿主）。

要在所有宿主中自动执行代码，请使用这个文件：

    $profile.CurrentUserAllHosts 
    
它们的路径基本上相同，除了后者文件名不含宿主名，而只是叫做“profile.ps1”。

<!--more-->
本文国际来源：[Using Profile Scripts](http://powershell.com/cs/blogs/tips/archive/2014/06/13/using-profile-scripts.aspx)
