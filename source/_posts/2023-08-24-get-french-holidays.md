---
layout: post
date: 2023-08-24 18:00:06
title: "PowerShell 技能连载 - 获取法国假期"
description: PowerTip of the Day - Get French Holidays
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
我看到了这篇[博客文章](https://blog.idera.com/database-tools/get-german-holidays/)，决定为法国发布这个。下面是一个获取所有法国假日的 PowerShell 函数：

```powershell
function Get-FrenchHoliday
{
    param
    (
        [int]
        $Year = (Get-Date).Year,

        [ValidateSet("alsace-moselle", "guadeloupe", "guyane", "la-reunion", "martinique", "mayotte", "metropole", "nouvelle-caledonie", "polynesie-francaise", "saint-barthelemy", "saint-martin", "saint-pierre-et-miquelon", "wallis-et-futuna")]
        [string]
        $Area = 'metropole',

        [switch]
        $NextOnly
    )

    $url = "https://calendrier.api.gouv.fr/jours-feries/$Area/$Year.json"

    $holidays = Invoke-RestMethod -Uri $url -UseBasicParsing

    foreach ($obj in $holidays.PSObject.Properties) {
        if (-Not ($NextOnly.IsPresent) -or (((([DateTime]$obj.Name).Ticks) - (Get-Date).Ticks) -gt 0)) {
            Write-Host "$($obj.Value) : $($obj.Name)"
        }
    }
}
```

运行上面的函数，然后运行这个命令：

```powershell
Get-FrenchHoliday
```

或者，提交额外的参数以获取特定地区的特定假日：

```powershell
Get-FrenchHoliday -NextOnly -Area guyane
```

```powershell
Get-FrenchHoliday -Area "alsace-moselle" -Year 2024
```
<!--本文国际来源：[Get French Holidays](https://blog.idera.com/database-tools/powershell/powertips/get-french-holidays/)-->

