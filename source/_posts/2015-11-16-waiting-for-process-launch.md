layout: post
date: 2015-11-16 12:00:00
title: "PowerShell 技能连载 - 等待进程启动"
description: PowerTip of the Day - Waiting for Process Launch
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
PowerShell 内置了等待一个进程或多个进程结束的功能：只需要用 `Wait-Process` 命令。

但是并不支持相反的功能：等待一个进程启动。以下是一个等待任意进程的函数：

    #requires -Version 1
    function Wait-ForProcess
    {
        param
        (
            $Name = 'notepad',
    
            [Switch]
            $IgnoreAlreadyRunningProcesses
        )
    
        if ($IgnoreAlreadyRunningProcesses)
        {
            $NumberOfProcesses = (Get-Process -Name $Name -ErrorAction SilentlyContinue).Count
        }
        else
        {
            $NumberOfProcesses = 0
        }
    
    
        Write-Host "Waiting for $Name" -NoNewline
        while ( (Get-Process -Name $Name -ErrorAction SilentlyContinue).Count -eq $NumberOfProcesses )
        {
            Write-Host '.' -NoNewline
            Start-Sleep -Milliseconds 400
        }
    
        Write-Host ''
    }

当您运行这段代码时，PowerShell 将会暂停直到您运行一个 Notepad 的新实例：

    Wait-ForProcess -Name notepad -IgnoreAlreadyRunningProcesses

当您忽略了 `-IgnoreAlreadyRunningProcesses` 参数时，如果已有至少一个 Notepad 的实例在运行，PowerShell 将会立即继续。

<!--more-->
本文国际来源：[Waiting for Process Launch](http://community.idera.com/powershell/powertips/b/tips/posts/waiting-for-process-launch)
