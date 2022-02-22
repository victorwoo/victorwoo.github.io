---
layout: post
date: 2022-02-17 00:00:00
title: "PowerShell 技能连载 - 本地化日期和时间标签（第 2 部分）"
description: PowerTip of the Day - Localizing Date and Time Labels (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了如何查看所有受支持的 Windows 文化并让 Windows 翻译工作日名称。让我们玩得更开心一些，翻译月份名称。

这是一种特别简单的方法，可以确认您想要使用的文化的简称：

```powershell
[System.Globalization.CultureInfo]::GetCultures('AllCultures') |
Where-Object Name |
Select-Object -Property Name, DisplayName |
Out-GridView -Title 'Select Culture' -OutputMode Single
```

这将打开一个包含所有支持的文化的网格视图窗口。使用位于其顶部的空文本框来过滤文化，然后选择一个并单击右下角的确定。您需要的是要使用的文化的简称。例如，要使用俄罗斯文化，简称为 "ru"。

现在，在以下调用中替换选定的文化名称：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultureInfo( 'ru' ).DateTimeFormat.MonthNames
Январь
Февраль
Март
Апрель
Май
Июнь
Июль
Август
Сентябрь
Октябрь
Ноябрь
Декабрь
```

同样，您可以调整我们之前技巧中的代码来创建两种语言的翻译表：

```powershell
$english = [System.Globalization.CultureInfo]::GetCultureInfo( 'en' ).DateTimeFormat.MonthNames
$russian = [System.Globalization.CultureInfo]::GetCultureInfo( 'ru' ).DateTimeFormat.MonthNames

for($x=0; $x-lt 12; $x++)
{

    [PSCustomObject]@{
        Id = $x+1
        English = $english[$x]
        Russian = $russian[$x]
    }
}
```

结果类似这样：

    Id English   Russian
    -- -------   -------
     1 January   Январь
     2 February  Февраль
     3 March     Март
     4 April     Апрель
     5 May       Май
     6 June      Июнь
     7 July      Июль
     8 August    Август
     9 September Сентябрь
    10 October   Октябрь
    11 November  Ноябрь
    12 December  Декабрь

<!--本文国际来源：[Localizing Date and Time Labels (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/localizing-date-and-time-labels-part-2)-->

