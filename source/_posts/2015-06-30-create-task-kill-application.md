layout: post
date: 2015-06-30 11:00:00
title: "PowerShell 技能连载 - 创建“结束进程”应用"
description: "PowerTip of the Day - Create “Task Kill” Application"
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
只需要通过一个管道命令，PowerShell 就能够打开一个包含正在运行的程序列表。您可以选择列表中的一个或多个进程（按住 `CTRL` 键选择多余一个条目），然后 PowerShell 可以结束选中的程序。

    Get-Process |
      Where-Object { $_.MainWindowHandle -ne 0 } |
      Select-Object -Property Name, Description, MainWindowTitle, Company, ID |
      Out-GridView -Title 'Choose Application to Kill' -PassThru |
      Stop-Process -WhatIf

请注意代码中使用了 `-WhatIf` 来模拟结束进程。如果您希望真的结束进程，那么移除 `-WhatIf` 代码。

结束程序会导致选中的应用程序立即停止。所有未保存的数据都会丢失。

<!--more-->
本文国际来源：[Create “Task Kill” Application](http://community.idera.com/powershell/powertips/b/tips/posts/create-task-kill-application)
