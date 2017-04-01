layout: post
date: 2015-05-15 11:00:00
title: "PowerShell 技能连载 - 获取内存消耗值"
description: PowerTip of the Day - Get Memory Consumption
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
要了解某个脚本占用内存的大约值，或是当您将结果存入变量时 PowerShell 写入多少内存，以下是一个辅助函数：

    #requires -Version 2
    
    $script:last_memory_usage_byte = 0
    
    function Get-MemoryUsage
    {
      $memusagebyte = [System.GC]::GetTotalMemory('forcefullcollection')
      $memusageMB = $memusagebyte / 1MB
      $diffbytes = $memusagebyte - $script:last_memory_usage_byte
      $difftext = ''
      $sign = ''
      if ( $script:last_memory_usage_byte -ne 0 )
      {
        if ( $diffbytes -ge 0 )
        {
          $sign = '+'
        }
        $difftext = ", $sign$diffbytes"
      }
      Write-Host -Object ('Memory usage: {0:n1} MB ({1:n0} Bytes{2})' -f  $memusageMB, $memusagebyte, $difftext)
    
      # save last value in script global variable
      $script:last_memory_usage_byte = $memusagebyte
    }

您可以在任意时候运行 `Get-MemoryUsage`，它将返回当前的内存消耗以及和上一次调用之间的变化量。

关键点在于使用垃圾收集器：它是负责清理内存，但是平时并不是立即清理内存。要粗略计算内存消耗时，需要调用垃圾收集器立即释放所有无用的内存，然后报告当前占用的内存。

<!--more-->
本文国际来源：[Get Memory Consumption](http://community.idera.com/powershell/powertips/b/tips/posts/get-memory-consumption)
