---
layout: post
date: 2014-08-18 11:00:00
title: "PowerShell 技能连载 - 用正则表达式搜索文件"
description: PowerTip of the Day - Searching Files with Regular Expressions
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

`Get-ChildItem` 不支持高级的文件过滤。当您使用简单的通配符时，无法利用上正则表达式。 

要用上正则表达式，需要增加一个过滤用的 cmdlet 和 `-match` 操作符。

这个例子将在 Windows 目录中查找所有文件名包含至少 2 位数字，且文件名不超过 8 个字符的文件：

    Get-ChildItem -Path $env:windir -Recurse -ErrorAction SilentlyContinue |
      Where-Object { $_.BaseName -match '\d{2}' -and $_.Name.Length -le 8 }
    
请注意 `BaseName` 属性的使用。它只返回主文件名（不包含扩展名）。通过这种方式，扩展名中的数字不会被包含在内。

<!--more-->
本文国际来源：[Searching Files with Regular Expressions](http://community.idera.com/powershell/powertips/b/tips/posts/searching-files-with-regular-expressions)
