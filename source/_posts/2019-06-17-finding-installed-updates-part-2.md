---
layout: post
date: 2019-06-17 00:00:00
title: "PowerShell 技能连载 - 查找已安装的更新（第 2 部分）"
description: PowerTip of the Day - Finding Installed Updates (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 更新客户端维护了它自己的已安装更新。下面的示例代码不是查询一般的系统事件日志，也不是主动搜索可能需要一些时间的更新，而是查询和读取 Windows Update 客户端的安装历史：

```powershell
    $Session = New-Object -ComObject Microsoft.Update.Session
      $Searcher = $Session.CreateUpdateSearcher()
      $HistoryCount = $Searcher.GetTotalHistoryCount()
      $Searcher.QueryHistory(1,$HistoryCount) |
      Select-Object Date, Title, Description, SupportUrl
```

<!--本文国际来源：[Finding Installed Updates (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-installed-updates-part-2)-->

