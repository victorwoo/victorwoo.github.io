layout: post
date: 2015-05-26 11:00:00
title: "PowerShell 技能连载 - 根据大写字符分割文本"
description: PowerTip of the Day - Splitting Text at Uppercase Letters
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
要在一段文本的每个大写字符出分割这段文本，而不用提供一个大写字符的列表，请试试这个例子：

    $text = 'MapNetworkDriveWithCredential'
    
    [Char[]]$raw = foreach ($character in $text.ToCharArray())
    {
      if ([Char]::IsUpper($character))
      {
        ' '
      }
      $character
    }
    
    $newtext = (-join $raw).Trim()
    $newtext

<!--more-->
本文国际来源：[Splitting Text at Uppercase Letters](http://powershell.com/cs/blogs/tips/archive/2015/05/26/splitting-text-at-uppercase-letters.aspx)
