---
layout: post
date: 2021-01-29 00:00:00
title: "PowerShell 技能连载 - 识别当前时区"
description: PowerTip of the Day - Identifying Current Time Zone
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
显然，您可以这样向您的计算机查询当前时区：

```powershell
PS> Get-TimeZone


Id                         : W. Europe Standard Time
DisplayName                : (UTC+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna
StandardName               : W. Europe Standard Time
DaylightName               : W. Europe Daylight Time
BaseUtcOffset              : 01:00:00
SupportsDaylightSavingTime : True
```

但是，此信息是否正确取决于您的实际配置。当您将笔记本电脑带到其他地方时，不一定会更新您的时区。

找出当前时区的另一种方法是调用公共 Web 服务。根据您当前的互联网连接，它会根据您当前所在的位置返回时区：

```powershell
PS> Invoke-RestMethod -Uri 'http://worldtimeapi.org/api/ip'


abbreviation : CET
client_ip    : 84.183.236.178
datetime     : 2021-01-04T13:31:57.398092+01:00
day_of_week  : 1
day_of_year  : 4
dst          : False
dst_from     :
dst_offset   : 0
dst_until    :
raw_offset   : 3600
timezone     : Europe/Berlin
unixtime     : 1609763517
utc_datetime : 2021-01-04T12:31:57.398092+00:00
utc_offset   : +01:00
week_number  : 1
```

<!--本文国际来源：[Identifying Current Time Zone](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-current-time-zone)-->

