---
layout: post
date: 2023-08-10 08:00:39
title: "PowerShell 技能连载 - 获取德国节日"
description: PowerTip of the Day - Get German Holidays
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个PowerShell函数，可以获取所有德国的假日，无论是全国范围还是只针对你所在的州。

```powershell
function Get-GermanHoliday
{
    param
    (
        [int]
        $Year = (Get-Date).Year,

        [ValidateSet("BB","BE","BW","BY","HB","HE","HH","MV","NATIONAL",
                     "NI","NW","RP","SH","SL","SN","ST","TH")]
        [string]
        $State = 'NATIONAL'
    )


    $url = "https://feiertage-api.de/api/?jahr=$Year"

    $holidays = Invoke-RestMethod -Uri $url -UseBasicParsing
    $holidays.$State
}
```

运行上面的函数，然后直接运行原样的命令：

```powershell
PS> Get-GermanHoliday

Neujahrstag               : @{datum=2023-01-01; hinweis=}
Karfreitag                : @{datum=2023-04-07; hinweis=}
Ostermontag               : @{datum=2023-04-10; hinweis=}
Tag der Arbeit            : @{datum=2023-05-01; hinweis=}
Christi Himmelfahrt       : @{datum=2023-05-18; hinweis=}
Pfingstmontag             : @{datum=2023-05-29; hinweis=}
Tag der Deutschen Einheit : @{datum=2023-10-03; hinweis=}
1. Weihnachtstag          : @{datum=2023-12-25; hinweis=}
2. Weihnachtstag          : @{datum=2023-12-26; hinweis=}
```

或者，提交额外的参数以获取给定州的特定假日：

```powershell
PS> Get-GermanHoliday -State ni -Year 2023
```

假设您想知道德国节日 "Christi Himmelfahrt" 的日期。以下是获取该信息的方法：

```powershell
# specify the name of the holiday to look up
$holidayName = 'Christi Himmelfahrt'

# get all holiday information
$holidays = Get-GermanHoliday
# get the particular holiday we are after, read the property "datum"
# and convert the string ISO format to a real DateTime:
$date = $holidays.$holidayName.datum -as [DateTime]
$date
```
<!--本文国际来源：[Get German Holidays](https://blog.idera.com/database-tools/powershell/powertips/get-german-holidays/)-->

