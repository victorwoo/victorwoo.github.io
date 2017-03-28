layout: post
date: 2014-07-17 11:00:00
title: "PowerShell 技能连载 - 删除别名"
description: PowerTip of the Day - Delete Aliases
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

虽然您可以轻松地用 `New-Alias` 和 `Set-Alias` 来创建新的别名，但是没有一个 cmdlet 可以删除别名。

    PS> Set-Alias -Name devicemanager -Value devmgmt.msc
    
    PS> devicemanager
    
    PS>  

要删除一个别名，您通常需要重启动您的 PowerShell。或者您可以通过 `Alias:` 虚拟驱动器删除它们：

    PS> del Alias:\devicemanager
    
    PS>

<!--more-->
本文国际来源：[Delete Aliases](http://community.idera.com/powershell/powertips/b/tips/posts/delete-aliases)
