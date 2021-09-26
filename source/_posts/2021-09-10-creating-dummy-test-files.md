---
layout: post
date: 2021-09-10 00:00:00
title: "PowerShell 技能连载 - Creating Dummy Test Files"
description: PowerTip of the Day - Creating Dummy Test Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
If you need to test file system load, test failover clusters, or need large dummy files otherwise, rather than creating new files and slowly filling them with random data, try this:

    $filepath = "$env:temp\testfile.txt"
    $sizeBytes = 5.75MB

    $file = [System.IO.File]::Create($filepath)
    $file.SetLength($sizeBytes)
    $file.Close()
    $file.Dispose()

    # show dummy file in Windows Explorer
    explorer /select,$filepath


This code creates dummy files of any size in a snap and can be used to quickly create storage load. Just don’t forget to delete these files after use.





<!--本文国际来源：[Creating Dummy Test Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-dummy-test-files)-->

