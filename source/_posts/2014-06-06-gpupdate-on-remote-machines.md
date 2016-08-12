layout: post
title: "PowerShell 技能连载 - 远程执行 gpupdate"
date: 2014-06-06 00:00:00
description: PowerTip of the Day - gpupdate on Remote Machines
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
您可以用这样的一段脚本远程执行 `gpupdate.exe`：

    function Start-GPUpdate
    {
        param
        (
            [String[]]
            $ComputerName 
        )
    
        $code = {     
            $rv = 1 | Select-Object -Property ComputerName, ExitCode
            $null = gpupdate.exe /force
            $rv.Exitcode = $LASTEXITCODE
            $rv.ComputerName = $env:COMPUTERNAME
            $rv  
        }
        Invoke-Command -ScriptBlock $code -ComputerName $ComputerName |
          Select-Object -Property ComputerName, ExitCode
    
    } 

`Start-GPUpdate` 接受一个或多个计算机名，然后对每台计算机运行 `gpupdate.exe`，并返回执行结果。

这段脚本利用了 PowerShell 远程管理技术，所以它需要目标计算机启用了 PowerShell 远程管理，并且您需要这些机器的本地管理员权限。

<!--more-->
本文国际来源：[gpupdate on Remote Machines](http://powershell.com/cs/blogs/tips/archive/2014/06/06/gpupdate-on-remote-machines.aspx)
