layout: post
date: 2014-10-31 11:00:00
title: "PowerShell 技能连载 - 创建新的共享文件夹"
description: PowerTip of the Day - Creating New Shares
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

WMI 可以方便地创建新的共享文件夹。以下是一段创建本地共享文件夹的代码：

    $ShareName = 'NewShare'
    $Path = 'c:\123'
    
    If (!(Get-WmiObject -Class Win32_Share -Filter "name='$ShareName'")) 
    { 
      $Shares=[WMICLASS]"WIN32_Share" 
      $Shares.Create($Path,$ShareName,0).ReturnValue
    }
    else
    {
      Write-Warning "Share $ShareName exists already."
    }

如果您有远程机器的管理员权限的话，也可以在远程的机器上创建共享文件夹。只需要像这样使用完整 WMI 即可：

    $ShareName = 'NewShare'
    $Path = 'c:\123'
    $Server = 'MyServer'
    
    If (!(Get-WmiObject -Class Win32_Share -Filter "name='$ShareName'")) 
    { 
      $Shares=[WMICLASS]"\\$Server\root\cimv2:WIN32_Share" 
      $Shares.Create($Path,$ShareName,0).ReturnValue
    }
    else
    {
      Write-Warning "Share $ShareName exists already."
    }

<!--more-->
本文国际来源：[Creating New Shares](http://community.idera.com/powershell/powertips/b/tips/posts/creating-newshares)
