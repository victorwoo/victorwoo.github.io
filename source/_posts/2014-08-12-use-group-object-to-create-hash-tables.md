layout: post
date: 2014-08-12 11:00:00
title: "PowerShell 技能连载 - 用 Group-Object 来创建哈希表"
description: PowerTip of the Day - Use Group-Object to Create Hash Tables
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
_适用于所有 PowerShell 版本_

`Group-Object` 能把对象输送到管道中，然后在一个管道中把属性相同的对象排在一起。

这个功能十分有用，特别是当您用 `Group-Object` 来返回哈希表时。它将生成一个按服务状态分组的哈希表：

    $hash = Get-Service | 
      Group-Object -Property Status -AsHashTable -AsString
    
您现在可以通过这种方式获取所有正在运行（或已停止的）服务：

    $hash.Running
    $hash.Stopped 

可以用任何想要的属性来分组。这个例子将用三个组来分组文件：一组为小文件，一个组为中等文件，另一个组位大文件。

    $code = 
    {
      if ($_.Length -gt 1MB)
      {'huge'}
      elseif ($_.Length -gt 10KB)
      {'average'}
      else
      {'tiny'}
    }
    
    $hash = Get-ChildItem -Path c:\windows |
      Group-Object -Property $code -AsHashTable -AsString
    
    
    #$hash.Tiny
    $hash.Huge

<!--more-->
本文国际来源：[Use Group-Object to Create Hash Tables](http://community.idera.com/powershell/powertips/b/tips/posts/use-group-object-to-create-hash-tables)
