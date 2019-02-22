---
layout: post
date: 2015-02-04 12:00:00
title: "PowerShell 技能连载 - 记录拒绝存取的文件夹"
description: PowerTip of the Day - Logging Folders with Access Denied Errors
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

当您用 `Get-ChildItem` 浏览文件系统的时候，您可能偶尔会碰到没有查看权限的文件夹。如果您希望将抛出次异常的所有文件夹都记录下来，请试试这个方法：

    $result = Get-ChildItem -Path c:\Windows -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue -ErrorVariable abcd
    
    Write-Warning 'Unable to access these folders:'
    Write-Warning ($abcd.TargetObject -join "`r`n") 

这个技巧是隐藏所有错误提示（`-ErrorAction SilentlyContinue`）但将错误都保存到一个变量中（`-ErrorVariable abce`）。

<!--本文国际来源：[Logging Folders with Access Denied Errors](http://community.idera.com/powershell/powertips/b/tips/posts/logging-folders-with-access-denied-errors)-->
