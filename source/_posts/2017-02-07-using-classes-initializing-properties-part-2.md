layout: post
date: 2017-02-07 00:00:00
title: "PowerShell 技能连载 - 使用类（初始化属性 - 第二部分）"
description: PowerTip of the Day - Using Classes (Initializing Properties - Part 2)
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
可以为类的属性手动指定一个数据类型和缺省值。当您从一个类实例化一个对象时，属性已经填充好并且只接受指定的数据类型：

```powershell
#requires -Version 5.0
class Info
{
  # strongly typed properties with default values
  [String]
  $Name = $env:USERNAME

  [String]
  $Computer = $env:COMPUTERNAME

  [DateTime]
  $Date = (Get-Date)
}

# create instance
$infoObj = [Info]::new()

# view default (initial) values
$infoObj

# change value
$infoObj.Name = 'test'
$infoObj
```

<!--more-->
本文国际来源：[Using Classes (Initializing Properties - Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/using-classes-initializing-properties-part-2)
