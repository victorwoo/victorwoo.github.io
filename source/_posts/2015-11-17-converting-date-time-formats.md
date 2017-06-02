---
layout: post
date: 2015-11-17 12:00:00
title: "PowerShell 技能连载 - 转换日期、时间格式"
description: PowerTip of the Day - Converting Date/Time Formats
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
以下是一个简单的 PowerShell 过滤器，它能够将任意的 `DateTime` 对象转换为您所需要的日期/时间格式：

    #requires -Version 1
    
    filter Convert-DateTimeFormat
    {
      param($OutputFormat='yyyy-MM-dd HH:mm:ss fff')
      
      try {
        ([DateTime]$_).ToString($OutputFormat)
      } catch {}
    }

以下是如何运行它的一些例子：

     
    PS> Get-Date | Convert-DateTimeFormat
    2015-10-23 14:38:37 140
    
    PS> Get-Date | Convert-DateTimeFormat -OutputFormat 'dddd'
    Friday
    
    PS> Get-Date | Convert-DateTimeFormat -OutputFormat 'MM"/"dd"/"yyyy'
    10/23/2015
    
    PS> '2015-12-24' | Convert-DateTimeFormat -OutputFormat 'dddd'
    Thursday

如您所见，您可以将 `DateTime` 类型数据，或是能够转换为 `DateTime` 类型的数据通过管道传给 `Convert-DateTimeFormat`。默认情况下，该函数以 ISO 格式格式化，但是您还可以通过 `-OutputFormat` 指定您自己的格式。

通过源码，您可以查看到类似日期和时间部分的字母。请注意这些字母是大小写敏感的（“m”代表分钟，而“M”代表月份）。并且您指定了越多的字母，就能显示越多的细节。

所有希望原样显示的文字必须用双引号括起来。

<!--more-->
本文国际来源：[Converting Date/Time Formats](http://community.idera.com/powershell/powertips/b/tips/posts/converting-date-time-formats)
