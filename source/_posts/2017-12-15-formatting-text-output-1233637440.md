---
layout: post
date: 2017-12-15 00:00:00
title: "PowerShell 技能连载 - 格式化文本输出"
description: PowerTip of the Day - Formatting Text Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您希望将输出文本格式化漂亮，您可能需要用 `PSCustomObject` 并且将它输出为一个格式化的列表，例如：

```powershell
$infos = [PSCustomObject]@{
    Success = $true
    Datum = Get-Date
    ID = 123
}

Write-Host ($infos| Format-List | Out-String) -ForegroundColor Yellow
```

实际使用时只需要增加或者调整哈希表中的键即可。

<!--本文国际来源：[Formatting Text Output](http://community.idera.com/powershell/powertips/b/tips/posts/formatting-text-output-1233637440)-->
