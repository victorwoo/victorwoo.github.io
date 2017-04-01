layout: post
date: 2014-12-11 12:00:00
title: "PowerShell 技能连载 - 查找进程所有者"
description: PowerTip of the Day - Finding Process Owners
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

要查看某个进程的所有者以及有多少个实例在运行，请试试以下这段代码：

    $ProcessName = 'explorer.exe'
    
    (Get-WmiObject -Query "select * from Win32_Process where name='$ProcessName'").GetOwner().User 

请注意：有许多办法能够查看当前登录的用户，并且根据您使用环境的不同，这里展示的方法可能有一定的局限性。它假设当前用户使用图形界面登录。由于在 server core 的机器上，只能运行非图形界面的进程，所以该脚本在该情况下不能检测连接到主机的用户名。

这个例子返回这台机器上所有“explorer.exe”进程的所有者。如果您有管理员权限并且远程进行此操作，那么该用户列表将类似已交互式登录的用户，因为每个桌面用户都创建了一个 explorer 进程。

当加入一个 `Sort-Object` 命令之后，您就可以轻松地排除重复项：

    $ProcessName = 'explorer.exe'
    
    (Get-WmiObject –Query "select * from Win32_Process where name='$ProcessName'").GetOwner().User |
      Sort-Object -Unique

如果改变进程名，您会发现其它有趣的东西。这段代码将列出当前通过 PowerShell 远程操作访问您机器的所有用户：

    $ProcessName = 'wsmprovhost.exe'
    
    try
    {
    
      (Get-WmiObject -Query "select * from Win32_Process where name='$ProcessName'").GetOwner().User |
      Sort-Object -Unique
    }
    catch
    {
      Write-Warning "No user found."
    }

<!--more-->
本文国际来源：[Finding Process Owners](http://community.idera.com/powershell/powertips/b/tips/posts/finding-process-owners)
