---
layout: post
date: 2017-08-03 00:00:00
title: "PowerShell 技能连载 - 查找已安装和缺失的更新（第二部分）"
description: PowerTip of the Day - Finding Installed Updates (and searching for missing) (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当 PowerShell 通过 `Microsoft.Update.Session` 对象向 Windows 请求更新时，一些信息似乎无法读取。以下代码获取已安装的更新信息。而 `KBArticleIDs` 只是显示为 `ComObject`。

```powershell
#requires -Version 2.0

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$updates = $Searcher.Search("IsInstalled=1").Updates

$updates |
    Select-Object -Property Title, LastDeploy*, Desc*, MaxDownload*, KBArticleIDs |
    Out-GridView
```

要解决这个问题，请使用计算属性。它能将无法读取的 COM 对象通过管道传给 `Out-String` 命令。通过这种方法，PowerShell 内部的内部逻辑使用它的魔力来解析 COM 对象内容：

```powershell
#requires -Version 2.0

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$updates = $Searcher.Search("IsInstalled=1").Updates

$KBArticleIDs = @{
    Name = 'KBArticleIDs'
    Expression = { ($_.KBArticleIDs | Out-String).Trim() }
}

$updates |
    Select-Object -Property Title, LastDeploy*, Desc*, MaxDownload*, $KBArticleIDs |
    Out-GridView
```

<!--本文国际来源：[Finding Installed Updates (and searching for missing) (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-installed-updates-and-searching-for-missing-part-2)-->
