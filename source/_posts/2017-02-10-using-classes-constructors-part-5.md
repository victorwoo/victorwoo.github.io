layout: post
date: 2017-02-10 00:00:00
title: "PowerShell 技能连载 - 使用类（构造函数 - 第五部分）"
description: PowerTip of the Day - Using Classes (Constructors - Part 5)
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
Class 也可以称为构造函数。构造函数是创建一个新对象的方法。构造函数只是和类名相同的方法。通过构造函数，可以更简单地创建事先为属性赋过值的对象。以下是一个例子：“`Person`”类定义了一个 person。

以下是一个构造函数，输入姓和名，以及生日。当一个对象实例化的时候，构造函数会被调用，并且事先填充好对象的属性：

```powershell
#requires -Version 5.0
class Person
{
    [string]$FirstName
    [string]$LastName
    [int][ValidateRange(0,100)]$Age
    [DateTime]$Birthday

    # constructor
    Person([string]$FirstName, [string]$LastName, [DateTime]$Birthday)
    {
    # set object properties
    $this.FirstName = $FirstName
    $this.LastName = $LastName
    $this.Birthday = $Birthday
    # calculate person age
    $ticks = ((Get-Date) - $Birthday).Ticks
    $this.Age = (New-Object DateTime -ArgumentList $ticks).Year-1
    }
}
```

有了这个类之后，您可以很方便地创建 person 对象的列表：

```powershell
[Person]::new('Tobias','Weltner','2000-02-03')
[Person]::new('Frank','Peterson','1976-04-12')
[Person]::new('Helen','Stewards','1987-11-19')
```

结果类似如下：

```powershell
FirstName LastName Age Birthday
--------- -------- --- --------
Tobias    Weltner   16 2/3/2000 12:00:00 AM
Frank     Peterson  40 4/12/1976 12:00:00 AM
Helen     Stewards  29 11/19/1987 12:00:00 AM
```

<!--more-->
本文国际来源：[Using Classes (Constructors - Part 5)](http://community.idera.com/powershell/powertips/b/tips/posts/using-classes-constructors-part-5)
