---
layout: post
date: 2020-09-29 00:00:00
title: "PowerShell 技能连载 - PowerShell技能连载-检查配置文件脚本（第 1 部分）"
description: PowerTip of the Day - Checking Profile Scripts (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 最多使用四个配置文件脚本。当它们存在时，PowerShell 在启动时会静默执行所有内容。

重要的是要知道存在哪个配置文件脚本（如果有），因为它们的内容会减慢 PowerShell 的启动时间，并且恶意代码可以使用它们来偷偷运行。

手动测试配置文件路径可能很麻烦。这是一行有趣的代码，可以为您完成工作：

```powershell
$profile.PSObject.Properties.Name | Where-Object { $_ -ne 'Length' } | ForEach-Object { [PSCustomObject]@{Profile=$_; Present=Test-Path $profile.$_; Path=$profile.$_}}
```

结果看起来像这样：

    Profile                Present Path
    -------                ------- ----
    AllUsersAllHosts         False C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1
    AllUsersCurrentHost      False C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1
    CurrentUserAllHosts      False C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\profile.ps1
    CurrentUserCurrentHost    True C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

<!--本文国际来源：[Checking Profile Scripts (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-profile-scripts-part-1)-->

