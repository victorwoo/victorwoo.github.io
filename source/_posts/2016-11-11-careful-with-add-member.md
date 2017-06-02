---
layout: post
date: 2016-11-11 00:00:00
title: "PowerShell 技能连载 - 使用 Add-Member 时请注意！"
description: PowerTip of the Day - Careful with Add-Member!
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
`Add-Member` 常用来创建自定义对象，例如：

```powershell
$o = New-Object -TypeName PSObject
$o | Add-Member -MemberType NoteProperty -Name Notes -Value 'Something'
$o | Add-Member -MemberType NoteProperty -Name Date -Value (Get-Date)

$o
```

这可以工作，结果类似这样：


    PS C:\> $o 

    Notes     Date                 
    -----     ----                 
    Something 10/28/2016 3:56:53 PM

然而，这样做效率不高。因为 `Add-Member` 时动态地扩展现有的对象，而不是创建新的对象。以上代码可以用这种方法更容易地实现：

```powershell
$o = [PSCustomObject]@{
  Notes = 'Something'
  Date  = Get-Date
  }

$o
```

`Add-Member` 可以做更多高级的事情，例如添加脚本属性和方法。请检查当您向以上对象添加动态脚本属性时发生了什么：

```powershell
$o = [PSCustomObject]@{
  Notes = 'Something'
  Date  = Get-Date
  }

$o | Add-Member -MemberType ScriptProperty -Name CurrentDate -Value { Get-Date }
```

现在请看多次查询该对象时，它的 `Date` 和 `CurrentDate` 属性

```
PS C:\> $o 

Notes     Date                  CurrentDate          
-----     ----                  -----------          
Something 10/28/2016 4:01:54 PM 10/28/2016 4:01:57 PM


​    
PS C:\> $o 

Notes     Date                  CurrentDate          
-----     ----                  -----------          
Something 10/28/2016 4:01:54 PM 10/28/2016 4:02:00 PM


​    
PS C:\> $o 

Notes     Date                  CurrentDate          
-----     ----                  -----------          
Something 10/28/2016 4:01:54 PM 10/28/2016 4:02:02 PM
```

`Date` 属性返回的是静态信息；而`CurrentDate` 属性总是返回当前时间，因为它的值是一个脚本，每次查询这个属性的时候都会执行一次。

<!--more-->
本文国际来源：[Careful with Add-Member!](http://community.idera.com/powershell/powertips/b/tips/posts/careful-with-add-member)
