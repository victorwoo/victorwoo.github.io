---
layout: post
date: 2020-12-18 00:00:00
title: "PowerShell 技能连载 - 读取已安装的软件（第 1 部分）"
description: PowerTip of the Day - Reading Installed Software (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-ItemProperty` cmdlet 可以比大多数用户知道的功能强大得多的方式读取注册表值。该 cmdlet 支持多个注册表路径，并且支持通配符。这样，只需一行代码即可从四个注册表项读取所有已安装的软件（及其卸载字符串）：

```powershell
# list of registry locations where installed software is stored
$paths =
# all users x64
'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
# all users x86
'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
# current user x64
'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
# current user x86
'HKCU:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

Get-ItemProperty -ErrorAction Ignore -Path $paths |
    # eliminate all entries with empty DisplayName
    Where-Object DisplayName |
    # select some properties (registry values)
    Select-Object -Property DisplayName, DisplayVersion, UninstallString, QuietUninstallString
```

<!--本文国际来源：[Reading Installed Software (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-installed-software-part-1)-->

