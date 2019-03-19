---
layout: post
date: 2016-08-31 00:00:00
title: "PowerShell 技能连载 - 替换类似 “Umlauts” 的特殊字符"
description: "PowerTip of the Day - Replacing Special Chars like “Umlauts”"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
*支持 PowerShell 2.0 以上版本*

有些时候我们需要将一些字符替换，例如德语的 "Umlauts"，来适应用户名或邮箱地址。

以下是一个演示如何实现这个功能的小函数：

```powershell
#requires -Version 3

function Convert-Umlaut
{
  param
  (
    [Parameter(Mandatory)]
    $Text
  )

  $output = $Text.Replace('ö','oe').Replace('ä','ae').Replace('ü','ue').Replace('ß','ss').Replace('Ö','Oe').Replace('Ü','Ue').Replace('Ä','Ae')
  $isCapitalLetter = $Text -ceq $Text.toUpper()
  if ($isCapitalLetter)
  {
    $output = $output.toUpper()
  }
  $output
}
```

要转换一个字符串，请这样使用：

```shell
PS C:\> Convert-Umlaut -Text "Mößler, Christiansön"
Moessler, Christiansoen
```

<!--本文国际来源：[Replacing Special Chars like “Umlauts”](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-special-chars-like-umlauts)-->
