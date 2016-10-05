layout: post
date: 2014-07-22 11:00:00
title: "PowerShell 技能连载 - 转换特殊字符（第二部分）"
description: PowerTip of the Day - Converting Special Characters, Part 2
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

在前一个技巧中我们演示了如何替换一段文本中的特殊字符。以下是另一种方法，虽然慢一点，但是更容易维护。它也演示了一个大小写敏感的哈希表：

    function ConvertTo-PrettyText($Text)
    {
      $hash = New-Object -TypeName HashTable
    
      $hash.'ä' = 'ae'
      $hash.'ö' = 'oe'
      $hash.'ü' = 'ue'
      $hash.'ß' = 'ss'
      $hash.'Ä' = 'Ae'
      $hash.'Ö' = 'Oe'
      $Hash.'Ü' = 'Ue'
        
      Foreach ($key in $hash.Keys)
      {
        $Text = $text.Replace($key, $hash.$key)
      }
      $Text
    }

请注意该函数并不是以 `@{}` 的方式定义一个哈希表，而是构造了一个 `HashTable` 对象。由于 PowerShell 所带的哈希表是大小写不敏感的，而这个函数创建的哈希表是大小写敏感的。这一点非常重要，因为该函数期望对大小写字母作区分。

    PS> ConvertTo-PrettyText -Text 'Mr. Össterßlim'
    Mr. Oesstersslim
    
    PS>  

如果您想要指定 ASCII 码，以下是一个用 ASCII 码作为键的变体：

    function ConvertTo-PrettyText($Text)   
    {  
      $hash = @{
        228 = 'ae'
        246 = 'oe'
        252 = 'ue'
        223 = 'ss'
        196 = 'Ae'
        214 = 'Oe'
        220 = 'Ue'   
      }
      
      foreach($key in $hash.Keys)
      {
        $Text = $text.Replace([String][Char]$key, $hash.$key)
      }
      $Text
    }

<!--more-->
本文国际来源：[Converting Special Characters, Part 2](http://community.idera.com/powershell/powertips/b/tips/posts/converting-special-characters-part-2)
