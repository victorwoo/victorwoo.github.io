---
layout: post
date: 2022-02-15 00:00:00
title: "PowerShell 技能连载 - 本地化日期和时间标签（第 1 部分）"
description: PowerTip of the Day - Localizing Date and Time Labels (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 内置了对各种文化的支持。以下是支持的文化列表及其简称：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultures('AllCultures') | Select-Object -Property Name, DisplayName

Name           DisplayName
----           -----------
aa             Afar
aa-DJ          Afar (Djibouti)
aa-ER          Afar (Eritrea)
aa-ET          Afar (Ethiopia)
af             Afrikaans
af-NA          Afrikaans (Namibia)
af-ZA          Afrikaans (South Africa)
...
```

它还带有完全翻译的日期和时间组件表达。如果您想知道 Kikuyu（肯尼亚）中使用的工作日名称，请查找适当的文化名称（ "ki"），然后尝试以下操作：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultureInfo( 'ki' ).DateTimeFormat.DayNames
Kiumia
Njumatatu
Njumaine
Njumatana
Aramithi
Njumaa
Njumamothi
```

你甚至可以为多种语言创建一个“翻译表”，因为你在 `DayNames` 中看到的是一个带有数字索引的数组：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultureInfo( 'ki' ).DateTimeFormat.DayNames[0]
Kiumia
```

这是一个显示英文和中文日期名称的翻译表：

```powershell
$english = [System.Globalization.CultureInfo]::GetCultureInfo( 'en' ).DateTimeFormat.DayNames
$chinese = [System.Globalization.CultureInfo]::GetCultureInfo( 'zh' ).DateTimeFormat.DayNames

for($x=0; $x-lt7; $x++)
{

    [PSCustomObject]@{
        English = $english[$x]
        Chinese = $chinese[$x]
    }
}
```

结果如下所示：

    English   Chinese
    -------   -------
    Sunday    星期日
    Monday    星期一
    Tuesday   星期二
    Wednesday 星期三
    Thursday  星期四
    Friday    星期五
    Saturday  星期六

<!--本文国际来源：[Localizing Date and Time Labels (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/localizing-date-and-time-labels-part-1)-->

