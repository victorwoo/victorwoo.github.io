---
layout: post
date: 2016-09-08 00:00:00
title: "PowerShell 技能连载 - 查看 ASCII 码"
description: PowerTip of the Day - Finding ASCII Codes
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
这是一种查看任何字符 ASCII 码的简单办法。字符可能截取自网站或者来自从 internet 上下载的脚本。

只需要打开 PowerShell 然后输入以下代码：

```powershell
# paste character(s)  inside the quotes   

$text = ''   

foreach($char in [char[]]$text)  

{  

  'Character {0,-3} Decimal {1,-5} Hex  {1,-4:X}' -f $char, [int]$char   

}
```

下一步，将字符（可以多个）粘贴在引号内，然后运行代码。为了测试，可以在 PowerShell 中运行以下代码：

```powershell
PS C:\> charmap
```

这将打开字符映射表。您可以在其中选择一种字体，例如 DingBats，以及一个或多个字符。将它们复制到剪贴板，然后将它们粘贴到上面的 PowerShell 代码中。当您运行代码时，它将以十进制和十进制两种方式返回所选字符的 ASCII 码值。它们应该和字符映射表工具状态栏显示的值相同。

<!--more-->
本文国际来源：[Finding ASCII Codes](http://community.idera.com/powershell/powertips/b/tips/posts/finding-ascii-codes)
