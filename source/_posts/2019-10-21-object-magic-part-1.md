---
layout: post
date: 2019-10-21 00:00:00
title: "PowerShell 技能连载 - 对象的魔法（第 1 部分）"
description: PowerTip of the Day - Object Magic (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中，大多数据是以 `PSObject` 来表示的，它是一个由 PowerShell 添加的特殊的对象“包装器”。要获取这个特殊的包装器，可以通过对象名为 "`PSObject`" 的隐藏属性。让我们来看看：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$object.PSObject

# get another object
$object = "Hello"

# try again
$object.PSObject
```

如您所见，该 "`PSObject`" 基本上是一个对象的描述。并且它包含了许多有用的信息。以下是一部分：

```powershell
# get any object
$object = Get-Process -Id $pid

# try and access the PSObject
$object.PSObject

# find useful information
$object.PSObject.TypeNames | Out-GridView -Title Type
$object.PSObject.Properties | Out-GridView -Title Properties
$object.PSObject.Methods | Out-GridView -Title Methods
```

<!--本文国际来源：[Object Magic (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/object-magic-part-1)-->

