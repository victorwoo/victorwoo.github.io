---
layout: post
date: 2017-02-06 00:00:00
title: "PowerShell 技能连载 - 使用类（创建对象 - 第一部分）"
description: PowerTip of the Day - Using Classes (Creating Objects - Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5.0 开始，引入了一个新的关键字 "class"。它能够创建新的类。您可以使用类作为新对象的模板。一下代码定义了一个名为 "Info" 的新类的模板，这个类有一系列属性：

```powershell
#requires -Version 5.0
class Info 
{ 
  $Name
  $Computer
  $Date 
}

# generic syntax to create a new object instance
$infoObj = New-Object -TypeName Info

# alternate syntax PS5 or better (shorter and faster)
$infoObj = [Info]::new()


$infoObj

$infoObj.Name = $env:COMPUTERNAME
$infoObj.Computer = $env:COMPUTERNAME
$infoObj.Date = Get-Date

$infoObj
$infoObj.GetType().Name
```

您可以使用 `New-Object` 来创建这个类的任意多个新实例。每个实例代表有三个属性的 "Info" 类型的一个新对象。

```powershell
Name            Computer        Date               
----            --------        ----               

DESKTOP-7AAMJLF DESKTOP-7AAMJLF 1/2/2017 2:00:02 PM
Info
```

这是一个非常简单（但很有用）的例子，演示了如何使用类来生产对象。如果您只希望在新对象中存储一些零碎信息，您也可以使用 PowerShell 3.0 引入的 `[PSCustomObject]` 语法：

```powershell
#requires -Version 3.0
$infoObj = [PSCustomObject]@{
  Name = $env:COMPUTERNAME
  Computer = $env:COMPUTERNAME
  Date = Get-Date
}

$infoObj
$infoObj.GetType().Name
```

这种做法没有使用一个蓝本（类），而是根据哈希表创建独立的新对象：

```powershell
Name            Computer        Date               
----            --------        ----               
DESKTOP-7AAMJLF DESKTOP-7AAMJLF 1/2/2017 2:02:39 PM
PSCustomObject
```

所以新创建的对象类型永远是 "`PSCustomObject`"；而在前一个例子中，对象的类型是通过类名定义的。

<!--本文国际来源：[Using Classes (Creating Objects - Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/using-classes-creating-objects-part-1)-->
