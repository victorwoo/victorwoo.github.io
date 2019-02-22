---
layout: post
date: 2016-11-03 00:00:00
title: "PowerShell 技能连载 - 获取 Cmdlet 参数的帮助"
description: PowerTip of the Day - Getting Help for Cmdlet Parameters
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 5.0 中似乎有个 bug，限制了内置帮助窗口的作用。当您以 `-ShowWindow` 参数运行 `Get-Help` 命令时，该窗口只显示该 cmdlet 的语法和例子。许多额外信息并没有显示出来。

要获得某个 cmdlet 支持的参数的详细信息，请直接请求该信息。以下代码将解释 `Get-Date` 中的 `-Format` 参数是做什么的：

    PS C:\> Get-Help -Name Get-Date -Parameter Format 
    
    -Format []
        Displays the date and time in the Microsoft .NET Framework format indicated by the 
        format specifier. Enter a format specifier. For a list of available format 
        specifiers, see DateTimeFormatInfo Class 
        (http://msdn.microsoft.com/library/system.globalization.datetimeformatinfo.aspx) 
        in MSDN.
        
        When you use the Format parameter, Windows PowerShell gets only the properties of 
        the DateTime object that it needs to display the date in the format that you 
        specify. As a result, some of the properties and methods of DateTime objects might 
        not be available.
        
        Starting in Windows PowerShell 5.0, you can use the following additional formats 
        as values for the Format parameter.
        
        -- FileDate. A file or path-friendly representation of the current date in local 
        time. It is in the form of yyyymmdd ( using 4 digits, 2 digits, and 2 digits). An 
        example of results when you use this format is 20150302.
        
        -- FileDateUniversal. A file or path-friendly representation of the current date 
        in universal time. It is in the form of yyyymmdd + 'Z' (using 4 digits, 2 digits, 
        and 2 digits). An example of results when you use this format is 20150302Z.
        
        -- FileDateTime. A file or path-friendly representation of the current date and 
        time in local time, in 24-hour format. It is in the form of yyyymmdd + 'T' + 
        hhmmssmsms, where msms is a four-character representation of milliseconds. An 
        example of results when you use this format is 20150302T1240514987.
        
        -- FileDateTimeUniversal. A file or path-friendly representation of the current 
        date and time in universal time, in 24-hour format. It is in the form of yyyymmdd 
        + 'T' + hhmmssmsms, where msms is a four-character representation of milliseconds, 
        + 'Z'. An example of results when you use this format is 20150302T0840539947Z.
        
        Required?                    false
        Position?                    named
        Default value                none
        Accept pipeline input?       false
        Accept wildcard characters?  false

通过这些信息，您现在可以知道如何格式化日期和时间：

```powershell
$date = Read-Host -Prompt 'Enter a date'
$weekday = Get-Date -Date $date -Format 'dddd'
"$date is a $weekday"
```

<!--本文国际来源：[Getting Help for Cmdlet Parameters](http://community.idera.com/powershell/powertips/b/tips/posts/getting-help-for-cmdlet-parameters)-->
