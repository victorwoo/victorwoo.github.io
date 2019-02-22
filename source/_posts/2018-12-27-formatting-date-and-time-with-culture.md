---
layout: post
date: 2018-12-27 00:00:00
title: "PowerShell 技能连载 - 格式化日期和时间（包含区域性）"
description: PowerTip of the Day - Formatting Date and Time (with Culture)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了 `Get-Date` 如何用格式化字符串将 `DateTime` 值转换为字符串。不过该字符串转换总是使用操作系统中的语言。这可能不是您想要的。现在我们来解决这个问题：

以下是输出 2018 圣诞前夕是周几的示例：

```powershell
$christmasEve = Get-Date -Date '2018-12-24'

Get-Date -Date $christmasEve -Format '"Christmas Eve in" yyyy "will be on" dddd.'
```

显然这是在德文系统上做的转换，所以结果中的周几是用德文显示的：

    Christmas Eve in 2018 will be on Montag.

如果您的脚本需要输出不同语言的结果，例如以英语（或其他语言）的方式来输出星期几。要控制语言，您需要意识到两件事：第一，`Get-Date` 和 `-Format` 的格式化选项只是通用的 .NET 方法 `ToString()` 的简单封装，所以您也可以运行这段代码获得相同的结果：

```powershell
$christmasEve = Get-Date -Date '2018-12-24'

$christmasEve.ToString('"Christmas Eve in" yyyy "will be on" dddd.')
```

第二，`ToString()` 方法有许多重载，其中一个能接受任何实现了 `IFormatProvider` 接口的对象，它们恰好包含了 "`CultureInfo`" 对象：

```powershell
PS> $christmasEve.ToString

OverloadDefinitions                                                                                     
-------------------                                                                                     
string ToString()                                                                                       
string ToString(string format)                                                                          
string ToString(System.IFormatProvider provider)                                                        
string ToString(string format, System.IFormatProvider provider)                                         
string IFormattable.ToString(string format, System.IFormatProvider formatProvider)                      
string IConvertible.ToString(System.IFormatProvider provider)   
```

以下是无论在什么语言的操作系统上都以英文输出周几的解决方案：

```powershell
$christmasEve = Get-Date -Date '2018-12-24'
$culture = [CultureInfo]'en-us'
$christmasEve.ToString('"Christmas Eve in" yyyy "will be on" dddd.', $culture)


Christmas Eve in 2018 will be on Monday. 
```

如果要显示其它地区的语言，例如要查看中文或泰文中“星期一”的表达：

```powershell
$christmasEve = Get-Date -Date '2018-12-24'
$culture = [CultureInfo]'zh'
$christmasEve.ToString('"Monday in Chinese: " dddd.', $culture)
$culture = [CultureInfo]'th'
$christmasEve.ToString('"Monday in Thai: " dddd.', $culture)



Monday in Chinese:  星期一.
Monday in Thai:  จันทร์.
```

<!--本文国际来源：[Formatting Date and Time (with Culture)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/formatting-date-and-time-with-culture)-->
