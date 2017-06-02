---
layout: post
date: 2014-07-14 11:00:00
title: "PowerShell 技能连载 - 创建优越的报告"
description: PowerTip of the Day - Creating Great Reports
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
当您克隆对象时，您可以修改它们的所有属性。克隆对象时可以导致原始对象“分离”，这是一个不错的主意。当您克隆了对象，您可以对该对象做任意的操作，例如修改或调整它的属性。

只需要用 `Select-Object` 命令就可以克隆对象。

这个例子列出文件夹中的内容，然后通过 `Select-Object` 处理，然后将其中的一些数据格式修饰一下。

    Get-ChildItem -Path c:\windows |
      # clone the objects and keep the properties you want/add new properties (like "age...")
      Select-Object -Property LastWriteTime, 'Age(days)', Length, Name, PSIsContainer |
      # change the properties of the cloned object as you like
      ForEach-Object {
        # calculate the file/folder age in days
        $_.'Age(days)' = (New-Timespan -Start $_.LastWriteTime).Days
    
        # if it is a file, change size in bytes to size in MB
        if ($_.PSisContainer -eq $false)
        {
          $_.Length = ('{0:N1} MB' -f ($_.Length / 1MB))
        }
    
        # do not forget to return the adjusted object so the next one gets it
        $_
      } |
      # finally, select the properties you want in your report:
      Select-Object -Property LastWriteTime, 'Age(days)', Length, Name |
      # sort them as you like:
      Sort-Object -Property LastWriteTime -Descending |
      Out-GridView 

该例子的结果以 MB 而不是字节为单位显示文件的大小，并且添加了一个称为“Age(days)”的列表示文件和文件夹创建以来的天数。

<!--more-->
本文国际来源：[Creating Great Reports](http://community.idera.com/powershell/powertips/b/tips/posts/creating-great-reports)
