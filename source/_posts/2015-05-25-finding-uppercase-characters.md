layout: post
date: 2015-05-25 11:00:00
title: "PowerShell 技能连载 - 查找大写字符"
description: PowerTip of the Day - Finding Uppercase Characters
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
如果您希望查找大写字符，那么可以使用正则表达式。然而，您也可以提供一个大写字符的列表作为对比使用。一个更灵活的办法是使用 .NET 的 `IsUpper()` 函数。

以下是一段示例代码：它逐字符扫描一段文本，然后返回首个大写字符的位置：

    $text = 'here is some text with Uppercase letters'
    
    $c = 0
    $position = foreach ($character in $text.ToCharArray())
    {
      $c++
      if ([Char]::IsUpper($character))
      {
        $c
        break
      }
    }
    
    if ($position -eq $null)
    {
      'No uppercase characters detected.'
    }
    else
    {
      "First uppercase character at position $position"
      $text.Substring(0, $position) + "<<<" + $text.Substring($position)
    }

执行的结果类似这样：

     
    PS C:\>
    
    First uppercase character at position 24
    here is some text with U<<<ppercase letters

<!--more-->
本文国际来源：[Finding Uppercase Characters](http://community.idera.com/powershell/powertips/b/tips/posts/finding-uppercase-characters)
