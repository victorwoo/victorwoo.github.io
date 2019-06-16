---
layout: post
date: 2019-06-14 00:00:00
title: "PowerShell 技能连载 - 查找已安装的更新（第 1 部分）"
description: PowerTip of the Day - Finding Installed Updates (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Hotfix` 返回已安装的更新，但实际上只是 Win32 `Win32_QuickFixEngineering` WMI 类的一个包装器。它并不会返回所有已安装的更新。

一个更好的方法可能是查询事件日志：

```powershell
Get-EventLog  -LogName System -InstanceId 19  |
    ForEach-Object {
        [PSCustomObject]@{
            Time = $_.TimeGenerated
            Update = $_.ReplacementStrings[0]
        }
    }
```

虽然这可能不完整，并且事件日志项有可能被清除。唯一权威的答案可能来自 Windows Update 客户端，它实际上是查看系统中的文件：

```powershell
$pattern = 'KB\d{6,9}'

$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateupdateSearcher()
$Updates = @($UpdateSearcher.Search("IsInstalled=1").Updates)
$Updates | ForEach-Object {
  $kb = 'N/A'
  if ($_.Title -match $pattern) { $kb = $matches[0] }
  [PSCustomObject]@{
    KB = $kb
    Title = $_.Title
  }
}
```

<!--本文国际来源：[Finding Installed Updates (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-installed-updates-part-1)-->

