layout: post
title: "PowerShell 技能连载 - 加速后台任务"
date: 2014-06-30 00:00:00
description: PowerTip of the Day - Speeding Up Background Jobs
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
后台任务可以大大提速脚本的执行，因为它们可以并行执行。然而，后台任务只适用于执行的代码不会产生大量的数据——因为通过 XML 序列化返回数据可能会消耗掉比串行操作节约出来的更多的时间。

幸运的是，您可以控制后台操作可以返回多少数据。让我们看看如何实现。

这段代码中有三个任务（$code1-3）并发执行。两个为后台任务，另一个操作 PowerShell 前台。

	$start = Get-Date
	
	$code1 = { Get-Hotfix }
	$code2 = { Get-ChildItem $env:windir\system32\*.dll }
	$code3 = { Get-Content -Path C:\Windows\WindowsUpdate.log }
	
	$job1 = Start-Job -ScriptBlock $code1 
	$job2 = Start-Job -ScriptBlock $code2
	$result3 = & $code3 
	
	$alljobs = Wait-Job $job1, $job2 
	
	Remove-Job -Job $alljobs
	$result1, $result2 = Receive-Job $alljobs
	
	$end = Get-Date
	$timespan = $end - $start
	$seconds = $timespan.TotalSeconds
	Write-Host "This took me $seconds seconds."
    
这将消耗大约半分钟时间。而当您顺序执行这三个任务，而不是用后台任务，它们只消耗 5 秒钟。

    $start = Get-Date
    
    $result1 = Get-Hotfix 
    $result2 = Get-ChildItem $env:windir\system32\*.dll 
    $result3 = Get-Content -Path C:\Windows\WindowsUpdate.log 
    
    $end = Get-Date
    $timespan = $end - $start
    $seconds = $timespan.TotalSeconds
    Write-Host "This took me $seconds seconds."
    
所以后台任务不仅增加了代码的复杂度，并且还延长了脚本的执行时间。只有优化过的返回数据才有意义。传递越少数据越好。

    $start = Get-Date
    
    $code1 = { Get-Hotfix | Select-Object -ExpandProperty HotfixID }
    $code2 = { Get-Content -Path C:\Windows\WindowsUpdate.log | Where-Object { $_ -like '*successfully installed*' }}
    $code3 = { Get-ChildItem $env:windir\system32\*.dll | Select-Object -ExpandProperty Name }
    
    $job1 = Start-Job -ScriptBlock $code1 
    $job2 = Start-Job -ScriptBlock $code2
    $result3 = & $code3 
    
    $alljobs = Wait-Job $job1, $job2 
    
    Remove-Job -Job $alljobs
    $result1, $result2 = Receive-Job $alljob 
    
这一次，后台任务只返回必须的数据，大大提升了执行效率。

总的来说，后台任务适合于做一些简单的事情（例如配置）而不返回任何数据或只返回少量的数据。

<!--more-->
本文国际来源：[Speeding Up Background Jobs](http://community.idera.com/powershell/powertips/b/tips/posts/speeding-up-background-jobs)
