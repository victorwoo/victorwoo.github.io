---
layout: post
date: 2014-07-21 11:00:00
title: "PowerShell 技能连载 - 转换特殊字符（第一部分）"
description: PowerTip of the Day - Converting Special Characters, Part 1
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于所有 PowerShell 版本_

有些时候我们需要将特殊字符转换为其它字符。以下是一个实现该功能的小函数：

    function ConvertTo-PrettyText($Text)
    {
      $Text.Replace('ü','ue').Replace('ö','oe').Replace('ä', 'ae' ).Replace('Ü','Ue').Replace('Ö','Oe').Replace('Ä', 'Ae').Replace('ß', 'ss')
    }

只要根据需要添加 `Replace()` 调用来处理文本即可。请注意 `Replace()` 是大小写敏感的，这样比较好：您可以针对大小写来做替换。

    PS> ConvertTo-PrettyText -Text 'Mr. Össterßlim'
    Mr. Oesstersslim

<!--本文国际来源：[Converting Special Characters, Part 1](http://community.idera.com/powershell/powertips/b/tips/posts/converting-special-characters-part-1)-->
