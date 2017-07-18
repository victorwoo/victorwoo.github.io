---
layout: post
date: 2017-07-14 00:00:00
title: "PowerShell 技能连载 - 设置 Powershell 标题文本"
description: PowerTip of the Day - Setting PowerShell Title Text
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
您也许知道可以通过类似这样一行代码改变 PowerShell 宿主窗口的标题文本：

```powershell
PS> $host.UI.RawUI.WindowTitle = "Hello  World!"
```

如果把这段代码加入 prompt 函数，标题文本就可以每次变化。

```powershell
function prompt
{
    # get current path
    $path = Get-Location

    # get current time
    $date = Get-Date -Format 'dddd, MMMM dd'

    # create title text
    $host.UI.RawUI.WindowTitle = ">>$path<< [$date]"

    # output prompt
    'PS> '
}
```

PowerShell 每次完成一条命令之后，都会执行 "`prompt`" 函数。在标题栏中，您将始终能看到当前的路径和日期，而 PowerShell 编辑器中的命令提示符被简化成 "PS> "。

<!--more-->
本文国际来源：[Setting PowerShell Title Text](http://community.idera.com/powershell/powertips/b/tips/posts/setting-powershell-title-text)
