layout: post
date: 2015-07-22 11:00:00
title: "PowerShell 技能连载 - 查找物理登录的用户"
description: PowerTip of the Day - Find Physically Logged On User
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
一台机器上只能有一个物理登录的用户。物理登录的用户意味着正坐在机器旁边的那个用户。

这个 PowerShell 函数能返回本地或远程系统物理登录的用户。要访问远程系统，您可能需要远程系统的本地管理员权限，并且确保防火墙已配置成允许连接。

    #requires -Version 1
    function Get-LoggedOnUser
    {
        param
        (
            $ComputerName,
            $Credential
        )
    
        Get-WmiObject -Class Win32_ComputerSystem @PSBoundParameters |
        Select-Object -ExpandProperty UserName
    }

运行 `Get-LoggedOnUser` 命令后能够获得本机上物理登录的用户名。指定 `-ComputerName`（或者 `-Credential`）参数可以获得远程机器上物理登录的用户名。

<!--more-->
本文国际来源：[Find Physically Logged On User](http://powershell.com/cs/blogs/tips/archive/2015/07/22/find-physically-logged-on-user.aspx)
