---
layout: post
date: 2021-11-25 00:00:00
title: "PowerShell 技能连载 - 通过 PowerShell 调用 COVID 服务"
description: PowerTip of the Day - COVID Webservice with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您想及时了解 Covid 疫情数据吗？试试这个简单的 webservice：

```powershell
$result = Invoke-RestMethod -Uri "https://coronavirus-19-api.herokuapp.com/countries"

$result -match "Germany"
```

结果类似于：

    country             : Germany
    cases               : 4480066
    todayCases          : 0
    deaths              : 95794
    todayDeaths         : 0
    recovered           : 4215200
    active              : 169072
    critical            : 1336
    casesPerOneMillion  : 53248
    deathsPerOneMillion : 1139
    totalTests          : 73348901
    testsPerOneMillion  : 871788

<!--本文国际来源：[COVID Webservice with PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/covid-webservice-with-powershell)-->

