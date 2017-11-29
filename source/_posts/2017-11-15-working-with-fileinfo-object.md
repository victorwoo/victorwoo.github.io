---
layout: post
date: 2017-11-15 00:00:00
title: "PowerShell 技能连载 - Working with [FileInfo] Object"
description: PowerTip of the Day - Working with [FileInfo] Object
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
Often, code needs to check on files, and for example test whether the file exists or exceeds a given size. Here is some commonly used code:

    $logFile = "$PSScriptRoot\mylog.txt"
    
    $exists = Test-Path -Path $logFile
    if ($exists)
    {
      $data = Get-Item -Path $logFile
      if ($data.Length -gt 100KB)
      {
        Remove-Item -Path $logFile
      }
    
    }
    

By immediately converting a string path into a FileInfo object, you can do more with less:

    [System.IO.FileInfo]$logFile = "$PSScriptRoot\mylog.txt"
    if ($logFile.Exists -and $logFile.Length -gt 0KB) { Remove-Item -Path $logFile }
    

You can convert any path to a FileInfo object, even if it is not representing a file. That’s what the property “Exists” is for: it tells you whether the file is present or not.

![Twitter This Tip!](/img/2017-11-15-working-with-fileinfo-object-001.gif)ReTweet this Tip!

<!--more-->
本文国际来源：[Working with [FileInfo] Object](http://community.idera.com/powershell/powertips/b/tips/posts/working-with-fileinfo-object)
