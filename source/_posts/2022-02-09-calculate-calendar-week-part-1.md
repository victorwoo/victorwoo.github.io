---
layout: post
date: 2022-02-09 00:00:00
title: "PowerShell 技能连载 - 计算第几周（第 1 部分）"
description: PowerTip of the Day - Calculate Calendar Week (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
计算第几周不是一件很容易的事，并且根据文化不同而不同。以下是一个计算任何日期是第几周的方法：

```powershell
# calculate day of week
# adjust calendar specs to your culture

$Date = [DateTime]'2021-12-31'
$CalendarWeekRule = [System.Globalization.CalendarWeekRule]::FirstDay
$FirstDayOfWeek   = [System.DayOfWeek]::Monday

$week = [System.Globalization.DateTimeFormatInfo]::CurrentInfo.Calendar.GetWeekOfYear( $date, $calendarWeekRule, $firstDayOfWeek )

"$date = week $week"
```

只需确保您按照当地文化调整了日历的周规则和一周的第一天。

前面的示例使用当前的文化日历。如果您想控制文化，请尝试使用这种方法：

```powershell
$Date = [DateTime]'2022-12-31'
$CultureName = 'de-de'
$CalendarWeekRule = [System.Globalization.CalendarWeekRule]::FirstDay
$FirstDayOfWeek   = [System.DayOfWeek]::Monday

$culture = [System.Globalization.CultureInfo]::GetCultureInfo($CultureName)
$week = $culture.Calendar.GetWeekOfYear($Date, $CalendarWeekRule, $FirstDayOfWeek)


"$Date = week $week"
```

在这里，您可以使用 `$CultureName` 来定义要使用的日历的文化名称。

<!--本文国际来源：[Calculate Calendar Week (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/calculate-calendar-week-part-1)-->

