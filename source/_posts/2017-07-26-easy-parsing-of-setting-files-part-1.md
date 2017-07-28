---
layout: post
date: 2017-07-26 00:00:00
title: "PowerShell 技能连载 - 简单解析设置文件（第一部分）"
description: PowerTip of the Day - Easy Parsing of Setting Files (Part 1)
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
假设您需要将设置用最简单的方式保存到一个文件中。设置文件可能看起来像这样：

```powershell
$settings = '
Name=Weltner
FirstName=Tobias
ID=12
Country=Germany
Conf=psconf.eu
'
```

您可以将这些设置用 `Set-Content` 保存到文件中，并用 `Get-Content` 再把它们读出来。

那么，如何解析该信息，来存取独立的项目呢？有一个名为 `ConvertFrom-StringData` 的 cmdlet，可以将键值对转化为哈希表：

```powershell
$settings = @'
Name=Weltner
FirstName=Tobias
ID=12
Country=Germany
Conf=psconf.eu
'@

$hash = $settings | ConvertFrom-StringData

$hash.Name
$hash.Country
```

<!--more-->
本文国际来源：[Easy Parsing of Setting Files (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/easy-parsing-of-setting-files-part-1)
