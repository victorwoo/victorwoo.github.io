---
layout: post
date: 2019-10-25 00:00:00
title: "PowerShell 技能连载 - 对象的魔法（第 3 部分）"
description: PowerTip of the Day - Object Magic (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您希望隐藏对象所有没有值（为空）的属性。以下是一个简单的实现：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$propNames = $object.PSObject.Properties.Where{$null -ne $_.Value}.Name
$object | Select-Object -Property $propNames
```

这段代码将只输出包含值的属性。您甚至可以对属性排序：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$propNames = $object.PSObject.Properties.Where{$null -ne $_.Value}.Name | Sort-Object
$object | Select-Object -Property $propNames
```

<!--本文国际来源：[Object Magic (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/object-magic-part-3)-->

