---
layout: post
date: 2017-08-02 00:00:00
title: "PowerShell 技能连载 - 查找已安装和缺失的更新（第一部分）"
description: PowerTip of the Day - Finding Installed Updates (and searching for missing) (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 可以自动确定系统中缺失的更新，在有 Internet 连接的情况下。PowerShell 可以使用相同的系统接口来查询该信息。以下代码返回系统中所有已安装的更新：

```powershell
#requires -Version 2.0

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$updates = $Searcher.Search("IsInstalled=1").Updates

$updates |
  Select-Object Title, LastDeployment*, Description, SupportUrl, MsrcSeverity |
  Out-GridView
```

要查看缺失的更新，请将 `IsInstalled=1` 改为 `IsInstalled=0`：

```powershell
#requires -Version 2.0

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$updates = $Searcher.Search("IsInstalled=0").Updates

$updates |
  Select-Object Title, LastDeployment*, Description, SupportUrl, MsrcSeverity |
  Out-GridView
```

<!--本文国际来源：[Finding Installed Updates (and searching for missing) (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-installed-updates-and-searching-for-missing-part-1)-->
