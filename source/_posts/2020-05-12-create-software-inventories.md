---
layout: post
date: 2020-05-12 00:00:00
title: "PowerShell 技能连载 - 创建软件库"
description: PowerTip of the Day - Create Software Inventories
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 注册表存储已安装的所有软件的名称和详细信息。PowerShell 可以读取该信息，并为您提供完整的软件清单：

```powershell
# read all child keys (*) from all four locations and do not emit
# errors if one of these keys does not exist
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore |
# list only items with the DisplayName
Where-Object DisplayName |
# show these registry values per item
Select-Object -Property DisplayName, DisplayVersion, UninstallString, InstallDate |
# sort by DisplayName
Sort-Object -Property DisplayName
```

如果您想添加更多信息（例如，软件是 32 位还是 64 位），或者要将代码转换为可重用的新 PowerShell 命令，请在此处阅读更多内容：[https://powershell.one/code/5.html](https://powershell.one/code/5.html)。

<!--本文国际来源：[Create Software Inventories](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/create-software-inventories)-->

