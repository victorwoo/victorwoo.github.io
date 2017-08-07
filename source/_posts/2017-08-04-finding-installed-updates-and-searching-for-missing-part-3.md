---
layout: post
date: 2017-08-04 00:00:00
title: "PowerShell 技能连载 - 查找已安装和缺失的更新（第三部分）"
description: PowerTip of the Day - Finding Installed Updates (and searching for missing) (Part 3)
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
当您想检查系统中已安装的更新，与其搜索在线更新，并和本地安装的更新比对，更好的方法是查询本地更新历史。

以下代码返回系统中所有已存在的更新。它不需要在线连接。

```powershell
#requires -Version 2.0
$Session = New-Object -ComObject "Microsoft.Update.Session"
$Searcher = $Session.CreateUpdateSearcher()
$historyCount = $Searcher.GetTotalHistoryCount()

$status = @{
    Name="Operation"
    Expression= {
        switch($_.operation)
        {
            1 {"Installation"}
            2 {"Uninstallation"}
            3 {"Other"}
        }
    }
}
$Searcher.QueryHistory(0, $historyCount) | 
Select-Object Title, Description, Date, $status |
Out-GridView
```

<!--more-->
本文国际来源：[Finding Installed Updates (and searching for missing) (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-installed-updates-and-searching-for-missing-part-3)
