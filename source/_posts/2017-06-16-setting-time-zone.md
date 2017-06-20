---
layout: post
date: 2017-06-16 00:00:00
title: "PowerShell 技能连载 - 设置时区"
description: PowerTip of the Day - Setting Time Zone
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
只有拥有了管理员特权才可以修改电脑的时间和日期，但任何用户都可以修改时区，例如当您在旅游时。PowerShell 5 提供了一系列非常简单的 cmdlet 来管理时区。首先，检查您的当前设置：

```powershell
PS> Get-TimeZone


Id                         : W. Europe Standard Time
DisplayName                : (UTC+01:00) Amsterdam, Berlin, Bern, Rom, Stockholm, Wien
StandardName               : Mitteleuropäische Zeit
DaylightName               : Mitteleuropäische Sommerzeit
BaseUtcOffset              : 01:00:00
SupportsDaylightSavingTime : True
```

下一步，尝试修改时区。以下代码打开一个包含所有可用时区的窗口：

```powershell
    PS> Get-TimeZone -ListAvailable | Out-GridView
```

当您知道您希望设置的时区的正式 ID 后，请使用 `Set-TimeZone` 命令。

```powershell
PS> Set-TimeZone -Id 'Chatham Islands Standard Time'

PS> Get-Date

Samstag, 27. Mai 2017 18:32:53



PS> Set-TimeZone -Id 'W. Europe Standard Time'

PS> Get-Date

Samstag, 27. Mai 2017 07:48:02
```

<!--more-->
本文国际来源：[Setting Time Zone](http://community.idera.com/powershell/powertips/b/tips/posts/setting-time-zone)
