layout: post
title: "PowerShell 技能连载 - 通过 StringBuilder 加速脚本"
date: 2014-07-03 00:00:00
description: PowerTip of the Day - Speeding Up Scripts with StringBuilder
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
我们的脚本常常需要向已有的文本中添加新的文本。以下是一段您可能很熟悉的代码：

    Measure-Command {
      $text = "Hello"
      for ($x=0; $x -lt 100000; $x++)
      {
        $text += "status $x"
      }
      $text 
    }

这段代码运行起来非常慢，因为当您向字符串中添加文本时，整个字符串都需要重新构造。然而，有一个专用的对象，叫做 `StringBuilder`。它可以做相同的事情，但是速度飞快：

    Measure-Command {
      $sb = New-Object -TypeName System.Text.StringBuilder
      $null = $sb.Append("Hello")
      
      for ($x=0; $x -lt 100000; $x++)
      {
        $null = $sb.Append("status $x")
      }
      
      $sb.ToString() 
    }

<!--more-->
本文国际来源：[Speeding Up Scripts with StringBuilder](http://community.idera.com/powershell/powertips/b/tips/posts/speeding-up-scripts-with-stringbuilder)
