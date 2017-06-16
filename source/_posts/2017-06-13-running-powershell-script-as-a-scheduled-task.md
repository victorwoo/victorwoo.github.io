---
layout: post
date: 2017-06-13 00:00:00
title: "PowerShell 技能连载 - 在计划任务中运行 PowerShell 脚本"
description: PowerTip of the Day - Running PowerShell Script as a Scheduled Task
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
如果您需要以固定的频率运行一段 PowerShell 脚本，何不以计划任务的方式运行它呢？以下是一段帮您新建一个每天上午 6 点执行一个 PowerShell 脚本的计划任务的代码：

```powershell
#requires -Modules ScheduledTasks
#requires -Version 3.0
#requires -RunAsAdministrator

$TaskName = 'RunPSScriptAt6'
$User= "train\tweltner"
$scriptPath = "\\Server01\Scripts\find-newaduser.ps1"

$Trigger= New-ScheduledTaskTrigger -At 6:00am -Daily 
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-executionpolicy bypass -noprofile -file $scriptPath" 
Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
```

<!--more-->
本文国际来源：[Running PowerShell Script as a Scheduled Task](http://community.idera.com/powershell/powertips/b/tips/posts/running-powershell-script-as-a-scheduled-task)
