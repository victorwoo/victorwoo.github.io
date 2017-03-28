layout: post
date: 2014-08-21 11:00:00
title: "PowerShell 技能连载 - 过滤 Hotfix 信息"
description: PowerTip of the Day - Filtering Hotfix Information
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
_适用于 PowerShell 所有版本_

`Get-HotFix` 是一个用于返回已安装的 hotfix 的 cmdlet。不过它没有可以过滤 hotfix 编号的参数。

通过一个 cmdlet 过滤器，您可以很方便地查看您关注的 hotfix。这个例子只返回编号为“KB25”开头的 hotfix：

    Get-HotFix |
      Where-Object { 
        $_.HotfixID -like 'KB25*'  
      }
    

请注意 `Get-HotFix` 有一个 `-ComputerName` 参数，所以如果您拥有了合适的权限，那么您也可以从远程计算机中获取 hotfix 信息。

<!--more-->
本文国际来源：[Filtering Hotfix Information](http://community.idera.com/powershell/powertips/b/tips/posts/filtering-hotfix-information)
