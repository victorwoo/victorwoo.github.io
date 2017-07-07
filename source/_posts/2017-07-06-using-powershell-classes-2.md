---
layout: post
date: 2017-07-06 00:00:00
title: "PowerShell 技能连载 - 使用 PowerShell 类（二）"
description: PowerTip of the Day - Using PowerShell Classes 2
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
从 PowerShell 5 开始，您可以定义 PowerShell 类。您可以使用类来创建新对象，并通过创建一个或多个构造函数，您可以方便地初始化新创建的对象。

让我们看看效果：

```powershell
class Employee
{
    [int]$Id
    [string]$Name

    Employee([int]$Id, [string]$Name)
    {
        $this.Id = $Id
        $this.Name = $Name
    }
    Employee ([string]$Name)
    {
        $this.Id = -1
        $this.Name = $Name
    }
    Employee ()
    {
        $this.Id = -1
        $this.Name = 'Undefined'
    }
}
```

这段代码运行后，将创建一个包含三个构造函数的 "Employee" 新类。以下是如何使用新类的方法：

```powershell
PS> [Employee]::new()

Id Name
-- ----
-1 Undefined



PS> [Employee]::new('Tobias')

Id Name
-- ----
-1 Tobias



PS> [Employee]::new(999, 'Tobias')

    Id Name
    -- ----
999 Tobias



PS>
```

每次调用都使用一个新的构造函数，并且该类根据需要创建相应的对象。

<!--more-->
本文国际来源：[Using PowerShell Classes 2](http://community.idera.com/powershell/powertips/b/tips/posts/using-powershell-classes-2)
