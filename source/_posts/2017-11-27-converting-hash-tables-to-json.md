---
layout: post
date: 2017-11-27 00:00:00
title: "PowerShell 技能连载 - 将哈希表转换为 JSON"
description: PowerTip of the Day - Converting Hash Tables to JSON
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
在前一个技能中我们大量操作了哈希表，甚至从 .psd1 文件中读取。如果您需要不同格式的数据，例如 JSON，那么转换工作很简单。需要做的只是先将哈希表转换为一个对象：

```powershell
$hash = @{
  Name = 'Tobias'
  ID = 12
  Path = 'c:\windows'
}

$object = [PSCustomObject]$hash

$object | ConvertTo-Json
```

当哈希表转换为一个对象以后，您可以将它用管道传递给 `ConvertTo-Json`，或其它的 `ConvertTo-*` 指令。

<!--more-->
本文国际来源：[Converting Hash Tables to JSON](http://community.idera.com/powershell/powertips/b/tips/posts/converting-hash-tables-to-json)
