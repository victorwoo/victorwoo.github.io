layout: post
date: 2015-03-18 11:00:00
title: "PowerShell 技能连载 - 从注册表中读取文件扩展名关联（第一部分）"
description: PowerTip of the Day - Reading Associated File Extensions from Registry
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
_适用于 PowerShell 所有版本_

PowerShell 代码可以写得十分紧凑。以下是一个从 Windows 注册表中读取所有文件扩展名关联的单行代码：

    Get-ItemProperty Registry::HKCR\.* | 
      Select-Object -Property PSChildName, '(default)', ContentType, PerceivedType

请注意这些技巧：`Get-ItemProperty` 使用了名为“`Registry::`”的 provider，而不是 PowerShell 提供的注册表驱动器。通过这种方式，您可以使用默认的注册表路径，并且可以存取类似 _HKEY\_CLASSES\_ROOT_ 这样没有驱动器的 hive。

请注意 `Select-Object` 如何选择获取注册表值。这里有两个特殊的名字：“`(default)`”总是代表缺省的注册表值，并且“`PSChildName`”总是代表当前读取的注册表键名。

由于路径名中的“`*`”符，该命令将自动读取 _HKCR_ 路径中以点开头的所有键。

<!--more-->
本文国际来源：[Reading Associated File Extensions from Registry](http://community.idera.com/powershell/powertips/b/tips/posts/reading-associated-file-extensions-from-registry)
