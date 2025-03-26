---
layout: post
date: 2023-07-17 08:00:41
title: "PowerShell 技能连载 - 星座计算器（又称“Sternzeichen”）"
description: "PowerTip of the Day - Zodiac Calculator (aka “Sternzeichen”)"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
想过自动将日期转换成星座吗？这里有一个非常简单的脚本，可以帮你实现这个功能，支持英文和德文：

```powershell
param (
[Parameter(Mandatory)]
[DateTime]$Date
)

$cutoff = $Date.toString('"0000-"MM-dd')
'Zodiac,Sternzeichen,StartDate
Capricorn,Steinbock,0000-01-20
Aquarius,Wassermann,0000-01-21
Pisces,Fische,0000-02-20
Aries,Widder,0000-03-21
Taurus,Stier,0000-04-21
Gemini,Zwillinge,0000-05-21
Cancer,Krebs,0000-06-22
Leo,Löwe,0000-07-23
Virgo,Jungfrau,0000-08-23
Libra,Waage,0000-09-23
Scorpio,Skorpion,0000-10-23
Sagittarius,Schütze,0000-11-22' |
ConvertFrom-Csv |
Where-Object StartDate -lt $cutoff |
Select-Object -Last 1
```
<!--本文国际来源：[Zodiac Calculator (aka “Sternzeichen”)](https://blog.idera.com/database-tools/powershell/powertips/zodiac-calculator-aka-sternzeichen/)-->

