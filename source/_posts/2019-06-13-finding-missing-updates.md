---
layout: post
date: 2019-06-13 00:00:00
title: "PowerShell 技能连载 - 寻找丢失的更新"
description: PowerTip of the Day - Finding Missing Updates
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可以使用 Windows Update 客户端相同逻辑查询缺少的更新：

```powershell
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateupdateSearcher()
$Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
$Updates | Select-Object Title
```

下面是返回更新标题和知识库编号（如果可用）的更复杂的方法：

```powershell
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateupdateSearcher()
$Updates = @($UpdateSearcher.Search("IsHidden=0 and IsInstalled=0").Updates)
$Updates |
ForEach-Object {
    $pattern = 'KB\d{6,9}'
    if ($_.Title -match $pattern)
    {
        $kb = $matches[0]
    }
    else
    {
        $kb = 'N/A'
    }
    [PSCustomObject]@{
        Title = $_.Title
        KB = $kb
    }
} | Out-GridView
```

<!--本文国际来源：[Finding Missing Updates](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-missing-updates)-->

