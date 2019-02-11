---
layout: post
date: 2019-02-01 00:00:00
title: "PowerShell 技能连载 - 格式化 DateTime"
description: PowerTip of the Day - Formatting a DateTime
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
当您拥有一个真正的 `DateTime` 对象（比如不是字符串）时，您就拥有了许多强大的格式化功能。您可以直接获取一个 `DateTime` 对象：

```powershell
PS> $installDate = (Get-CimInstance -Class Win32_OperatingSystem).InstallDate

PS> $installDate.GetType().FullName
System.DateTime
```

或者您可以将一个字符串转换为一个 `DateTime` 对象：

```powershell
PS> $psconf = Get-Date -Date '2019-06-04 09:00'

PS> $psconf.GetType().FullName
System.DateTime
```

当您拥有一个 `DateTime` 对象时，请使用 `ToString()` 方法并提供一个或两个参数。

第一个参数决定您希望使用日期的哪些部分，并使用这些占位符（大小写敏感！）：

    y       Year
    M       Month
    d       Day
    H       Hour
    m       Minute
    s       Second
    f       Millisecond

指定了越多占位符，就可以得到越多的细节：

```powershell
PS> (Get-Date).ToString('dd')
30

PS> (Get-Date).ToString('ddd')
So

PS> (Get-Date).ToString('dddd')
Sonntag

PS>
```

（如您所见，PowerShell 使用的是缺省的语言，这个例子中使用的是德语）

要以 ISO 格式输出一个 `DateTime`，请使用这段代码：

```powershell
PS> $installDate = (Get-CimInstance -Class Win32_OperatingSystem).InstallDate

PS> $installDate.ToString('yyyy-MM-dd HH:mm:ss')
2018-06-08 18:24:46

PS>
```

如果您也希望指定区域设置（语言），请在第二个参数指定 `CultureInfo`：

```powershell
PS> (Get-Date).ToString('dddd', [System.Globalization.CultureInfo]'en-us')
Sunday

PS> (Get-Date).ToString('dddd', [System.Globalization.CultureInfo]'zh')
星期日

PS> (Get-Date).ToString('dddd', [System.Globalization.CultureInfo]'es')
domingo

PS> (Get-Date).ToString('dddd', [System.Globalization.CultureInfo]'fr')
dimanche

PS>
```

如果您想了解某个区域设置的区域代码，请试试这段代码：

```powershell
PS> [System.Globalization.CultureInfo]::GetCultures('Installed') | Out-GridView -PassThru
```

<!--more-->
本文国际来源：[Formatting a DateTime](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/formatting-a-datetime)
