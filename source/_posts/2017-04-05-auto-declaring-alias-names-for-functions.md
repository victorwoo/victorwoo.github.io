---
layout: post
date: 2017-04-05 00:00:00
title: "PowerShell 技能连载 - 自动定义函数的别名"
description: PowerTip of the Day - Auto-Declaring Alias Names for Functions
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
您也许知道 PowerShell 支持命令的别名。但是您是否知道也可以在函数定义内部为 PowerShell 函数定义别名（PowerShell 4 引入的功能）呢？让我们来看看：

```powershell
function Get-AlcoholicBeverage
{
    [Alias('Beer','Drink')]
    [CmdletBinding()]
    param()

    "Here is your beer."
}
```

这个函数的“正式”名称是 `Get-AlcoholicBeverage`，但是这个函数也可以通过 "`Beer`" 和 "`Drink`" 别名来引用。在函数定义时，PowerShell 自动增加了这些别名：

```powershell
CommandType     Name
-----------     ----
Alias           Beer -> Get-AlcoholicBeverage
Alias           Drink -> Get-AlcoholicBeverage
```

<!--more-->
本文国际来源：[Auto-Declaring Alias Names for Functions](http://community.idera.com/powershell/powertips/b/tips/posts/auto-declaring-alias-names-for-functions)
