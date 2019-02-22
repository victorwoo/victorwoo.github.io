---
layout: post
date: 2015-07-01 11:00:00
title: "PowerShell 技能连载 - 创建友好的“结束进程”应用程序"
description: "PowerTip of the Day - Create Benign “Task Kill” Application"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们展示了如何选择应用程序并且立即结束它们。所有未保存的数据将会丢失。

这是一个更复杂的实现。它可以列出所有的应用程序，您可以选择希望结束的应用程序（按住 `CTRL` 键选择多个应用程序）。

该脚本接下来尝试向选中的应用程序发送“关闭窗口”消息。用户将有机会保存未保存的数据。用户也可以取消“关闭窗口”消息。

This is why the script waits for 15 seconds, and then checks whether the requested applications actually ended. If not, these applications are killed immediately (remove –WhatIf to actually kill them):
这是为什么该脚本等待 15 秒，然后确认请求的应用程序是否确实已结束的原因。如果指定的尚未结束，则此时立即结束（移除 `-WhatIf` 可以真正结束它们）：

    #requires -Version 3
    
    $list = Get-Process |
        Where-Object -FilterScript {
            $_.MainWindowHandle -ne 0
        } |
        Select-Object -Property Name, Description, MainWindowTitle, Company, ID |
        Out-GridView -Title 'Choose Application to Kill' -PassThru
    
    # try and close peacefully
    $list.ID | ForEach-Object -Process {
        $process = Get-Process -Id $_
        $null = $process.CloseMainWindow()
    }
    
    # give user 15 seconds to respond
    Start-Sleep -Seconds 15
    
    # check to see if selected programs closed, and if not, kill
    # them anyway (remove -WhatIf to actually kill them)
    $list.ID |
    ForEach-Object -Process {
        Get-Process -Id $_ -ErrorAction SilentlyContinue
        } |
        Where-Object -FilterScript {
            $_.hasExited -eq $false
        } |
        Stop-Process -WhatIf

<!--本文国际来源：[Create Benign “Task Kill” Application](http://community.idera.com/powershell/powertips/b/tips/posts/create-benign-task-kill-application)-->
