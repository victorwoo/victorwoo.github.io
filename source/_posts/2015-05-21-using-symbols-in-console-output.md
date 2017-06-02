---
layout: post
date: 2015-05-21 11:00:00
title: "PowerShell 技能连载 - 在控制台输出中使用符号"
description: PowerTip of the Day - Using Symbols in Console Output
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
您知道吗，控制台输出内容可以包括特殊字符，例如复选标记？您所需要做的只是将控制台设成 TrueType 字体，例如“Consolas”。

要显示特殊字体，请使用十进制或十六进制字符代码，例如：

    [Char]8730
    
    
    [Char]0x25BA

或者执行内置的“CharacterMap”程序以您选择的控制台字体选择另一个特殊字符。

以下是一个让您在 PowerShell 控制台中得到更复杂提示的示例代码：

    function prompt
    {
    
      $specialChar1 = [Char]0x25ba
    
      Write-Host 'PS ' -NoNewline
      Write-Host $specialChar1 -ForegroundColor Green -NoNewline
      ' '
    
      $host.UI.RawUI.WindowTitle = Get-Location
    }

请注意“`prompt`”函数必须返回至少一个字符，否则 PowerShell 将使用它的默认提示信息。这是为什么该函数用一个空格作为返回值，并且使用 `Write-Host` 作为彩色输出的原因。

<!--more-->
本文国际来源：[Using Symbols in Console Output](http://community.idera.com/powershell/powertips/b/tips/posts/using-symbols-in-console-output)
