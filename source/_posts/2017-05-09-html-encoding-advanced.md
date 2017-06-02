---
layout: post
date: 2017-05-09 00:00:00
title: "PowerShell 技能连载 - HTML 高级编码"
description: PowerTip of the Day - HTML Encoding Advanced
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
.NET 静态方法 `HtmlEncode` 能够较好地将普通字符进行编码，但是对于许多特殊字符会处理失败。要正确地对所有字符编码，我们编写了一个 `ConvertTo-EncodedHtml` 函数：

```powershell
function ConvertTo-EncodedHTML($HtmlText)
{

  $chars = [Web.HttpUtility]::HtmlEncode($HtmlText).ToCharArray()
  $txt = New-Object System.Text.StringBuilder
  $null = . {
      foreach($c in $chars)
      {
        if ([int]$c -gt 127)
        {
          $txt.Append("&#" + [int]$c + ";")
        }
        else
        {
          $txt.Append($c)
        }
    }
    }
    return $txt.ToString()
}
```

这个函数检查所有 ASCII 代码大于 127 的字符并将这些字符转换为编码后的版本：

```powershell
PS> Convert-EncodedHTML -HtmlText "A – s ‘Test’"
A &#8211; s  &#8216;Test&#8217;
```

<!--more-->
本文国际来源：[HTML Encoding Advanced](http://community.idera.com/powershell/powertips/b/tips/posts/html-encoding-advanced)
