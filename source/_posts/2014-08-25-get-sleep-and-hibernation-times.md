---
layout: post
date: 2014-08-25 11:00:00
title: "PowerShell 技能连载 - 获取睡眠或休眠的时间"
description: PowerTip of the Day - Get Sleep and Hibernation Times
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

如果您希望确认某台机器是否频繁地进入睡眠或者休眠模式，以下是一个读取对应的日志并返回详细信息的函数。它能汇报计算机何时进入睡眠模式，以及它进入睡眠模式的时长：

    function Get-HibernationTime
    {
      
      # get hibernation events
      Get-EventLog -LogName system -InstanceId 1 -Source Microsoft-Windows-Power-TroubleShooter |
      ForEach-Object {    
        # create new object for results
        $result = 'dummy' | Select-Object -Property ComputerName, SleepTime, WakeTime, Duration
        
        # store details in new object, convert datatype where appropriate
        [DateTime]$result.Sleeptime = $_.ReplacementStrings[0]
        [DateTime]$result.WakeTime = $_.ReplacementStrings[1]
        $time = $result.WakeTime - $result.SleepTime
        $result.Duration = ([int]($time.TotalHours * 100))/100
        $result.ComputerName = $_.MachineName
        
        # return result
        $result
      }
    }

<!--本文国际来源：[Get Sleep and Hibernation Times](http://community.idera.com/powershell/powertips/b/tips/posts/get-sleep-and-hibernation-times)-->
