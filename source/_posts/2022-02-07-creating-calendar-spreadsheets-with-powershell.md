---
layout: post
date: 2022-02-07 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 创建日历电子表格"
description: PowerTip of the Day - Creating Calendar Spreadsheets with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否需要计划为您的俱乐部，社区或爱好进行重复的会议吗？当然，有很多在线工具可以帮助您，但如果您想在 Microsoft Excel 中创建日历列表，PowerShell 可以是一个优秀的帮手。

让我们假设您每周三都有一次重复的会议，会议在下午十二点开始，除了每个月的最后一周。

您可以这样使用 PowerShell，而不是将这些日期和时间手动添加到 Excel 表：

```powershell
# generate calendar for weekly incidents

$startdate = [DateTime]'2022-06-01'
$numberOfWeeks = 52
$result = for ($week = 0; $week -lt $numberOfWeeks; $week ++)
{
  # calculate the real date each week
  $realdate = $startdate + (New-Timespan -days (7*$week))

  # calculate the current month
  $month = $realdate.Month

  # calculate the days in this month
  $daysInMonth = [DateTime]::DaysInMonth($realdate.Year, $realdate.Month)

  # make arbitrary adjustments, i.e. set start time to 12PM by default, but 7PM on the last week of a month

  # are we in the last week of a month?
  if ($realdate.Day -gt ($daysInMonth-7))
  {
    # add 19 hours
    $realdate = $realdate.AddHours(19)
  }
  else
  {
    # add 12 hours
    $realdate = $realdate.AddHours(12)
  }

  # create your Excel sheet layout as a CSV file
  [PSCustomObject]@{
    Start = $realdate
    IsOnline = $false
    Title = ''
    Speaker = ''
    Notes = ''
  }
}


$path = "$env:temp\calendar.csv"
$result | Export-Csv -UseCulture -Path $path -Encoding UTF8 -NoTypeInformation

# open CSV in Excel
Start-Process -FilePath excel -ArgumentList $path
```

此脚本使用了许多有用的技术：

* 在循环中使用偏移量来构建日期（在此示例中是 7 天，可以轻松调整成任何其他间隔）
* 通过计算当前月份的天数来识别“该月的最后一周”，然后根据此计算日期进行调整
* 在 Microsoft Excel 中生成 CSV 数据和打开 CSV（如果已安装）

<!--本文国际来源：[Creating Calendar Spreadsheets with PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-calendar-spreadsheets-with-powershell)-->

