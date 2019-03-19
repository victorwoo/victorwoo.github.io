---
layout: post
date: 2014-09-26 11:00:00
title: "PowerShell 技能连载 - 替换重复的空格"
description: PowerTip of the Day - Replacing Duplicate Spaces
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

要删除重复的空格，请使用这个正则表达式：

    PS> '[  Man, it    works!   ]' -replace '\s{2,}', ' '
    [ Man, it works! ]

您也可以用这种方式将固定宽度的文本表格转成 CSV 数据：

    PS> (qprocess) -replace '\s{2,}', ','
    >tobias,console,1,3876,taskhostex.exe
    >tobias,console,1,3844,explorer.exe
    >tobias,console,1,4292,tabtip.exe

当得到 CSV 数据之后，您可以用 `ConvertFrom-Csv` 将文本数据转换为对象：

    PS> (qprocess) -replace '\s{2,}', ',' | ConvertFrom-Csv -Header Name, Session, ID, Pid, Process


    Name    : >tobias
    Session : console
    ID      : 1
    Pid     : 3876
    Process : taskhostex.exe

    Name    : >tobias
    Session : console
    ID      : 1
    Pid     : 3844
    Process : explorer.exe

    Name    : >tobias
    Session : console
    ID      : 1
    Pid     : 4292
    Process : tabtip.exe
    (...)

<!--本文国际来源：[Replacing Duplicate Spaces](http://community.idera.com/powershell/powertips/b/tips/posts/replacing-duplicate-spaces)-->
