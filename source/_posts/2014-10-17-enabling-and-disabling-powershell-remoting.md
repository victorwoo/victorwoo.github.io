layout: post
date: 2014-10-17 11:00:00
title: "PowerShell 技能连载 - 启用、禁用 PowerShell 远程操作"
description: PowerTip of the Day - Enabling and Disabling PowerShell Remoting
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
_适用于 PowerShell 3.0 及更高版本_

如果您想通过 PowerShell 访问一台远程计算机，那么在目标机器（您想访问的机器）上，以管理员身份运行这行代码：

    PS> Enable-PSRemoting -SkipNetworkProfileCheck -Force  

执行完之后，您就可以通过别的计算机访问该计算机了——假设您拥有目标机器的管理员权限，您需要指定计算机名而不是它的 IP 地址，并且两台机器都需要在同一个域中。

要交互式地连接目标机器，使用这行代码：

    PS> Enter-PSSession -ComputerName targetComputerName 

要在远程计算机上运行代码，请使用这种方式：

    PS> Invoke-Command -ScriptBlock { Get-Service } -ComputerName targetComputerName

<!--more-->
本文国际来源：[Enabling and Disabling PowerShell Remoting](http://community.idera.com/powershell/powertips/b/tips/posts/enabling-and-disabling-powershell-remoting)
