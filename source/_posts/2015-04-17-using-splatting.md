layout: post
date: 2015-04-17 11:00:00
title: "PowerShell 技能连载 - 使用 Splatting 技术"
description: PowerTip of the Day - Using Splatting
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
通过 splatting 技术，您可以调用 cmdlet，并可以控制提交的参数。

要实现该目标，先向一个哈希表插入参数和值，然后将哈希表传给 cmdlet。这种方法适用于任意 cmdlet。

以下是一个例子：

    # classic:
    Get-ChildItem -Path c:\windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue
    
    
    # Splatting
    $params = @{}
    $params.Path = 'c:\windows'
    $params.Filter = '*.ps1'
    $params.Recurse = $true
    $params.ErrorAction = 'SilentlyContinue'
    Get-ChildItem @params

<!--more-->
本文国际来源：[Using Splatting](http://community.idera.com/powershell/powertips/b/tips/posts/using-splatting)
