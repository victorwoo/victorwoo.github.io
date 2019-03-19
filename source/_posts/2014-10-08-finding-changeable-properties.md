---
layout: post
date: 2014-10-08 11:00:00
title: "PowerShell 技能连载 - 查找可改变的属性"
description: PowerTip of the Day - Finding Changeable Properties
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

当您从 PowerShell cmdlet 中获取结果时，返回的结果都是包含属性的对象。有些属性是可改变的，另一些是只读的。

以下是一个获取可改变的属性的简单技巧。这段代码是以当前 PowerShell 宿主的进程对象为例，但您可以用任意的 cmdlet 结果。

    $myProcess = Get-Process -Id $Pid

    $myProcess |
      Get-Member -MemberType Properties |
      Out-String -Stream |
      Where-Object { $_ -like '*set;*' }

结果类似如下：


    EnableRaisingEvents        Property       bool EnableRaisingEvents {get;set;}
    MaxWorkingSet              Property       System.IntPtr MaxWorkingSet  {get;set;}
    MinWorkingSet              Property       System.IntPtr MinWorkingSet  {get;set;}
    PriorityBoostEnabled       Property       bool PriorityBoostEnabled  {get;set;}

<!--本文国际来源：[Finding Changeable Properties](http://community.idera.com/powershell/powertips/b/tips/posts/finding-changeable-properties)-->
