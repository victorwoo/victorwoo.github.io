layout: post
title: "PowerShell 技能连载 - 应用 NTFS 存取权限"
date: 2014-03-21 00:00:00
description: PowerTip of the Day - Applying NTFS Access Rules
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
有很多方法可以增加或修改 NTFS 权限。其中一个方法是复用现成的工具，例如 `icacls.exe`。

这个函数将以缺省权限创建新的文件夹。该脚本使用 `icacls.exe` 来显式地为当前用户添加完全权限以及为本地管理员添加读取权限：

    function New-Folder 
    {
      param
      (
        [String]
        $path,
        
        [String]
        $username = "$env:userdomain\$env:username"
      )
      
      If ( (Test-Path -Path $path) -eq $false ) 
      {
        New-Item $path -Type Directory | Out-Null
      }
      
      icacls $path /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)R' ('{0}:(OI)(CI)F' -f $username)
    } 
    
<!--more-->
本文国际来源：[Applying NTFS Access Rules](http://powershell.com/cs/blogs/tips/archive/2014/03/21/applying-ntfs-access-rules.aspx)
