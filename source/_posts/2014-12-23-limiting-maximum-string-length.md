layout: post
date: 2014-12-23 12:00:00
title: "PowerShell 技能连载 - 限制 String 的最大长度"
description: 'PowerTip of the Day - Limiting Maximum String Length '
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

要限制输出的文本不会过长，您可以使用类似这样的的逻辑来缩短超过指定长度的文本：

    if ($text.Length -gt $MaxLength)
    {
      $text.Substring(0,$MaxLength) + '...'
    }
    else
    {
      $text
    }

<!--more-->
本文国际来源：[Limiting Maximum String Length ](http://community.idera.com/powershell/powertips/b/tips/posts/limiting-maximum-string-length)
