---
layout: post
date: 2020-03-03 00:00:00
title: "PowerShell 技能连载 - 列出安装的应用程序（第 1 部分）"
description: PowerTip of the Day - Listing Installed Applications (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否想知道启动一个应用程序的运行路径？Windows 注册表中有存储以下信息的键：

```powershell
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

$lookup = Get-ItemProperty -Path $key |
Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore |
Where-Object { $_ } |
Sort-Object
```

结果是已注册的应用程序路径的排序列表。您可以轻松地将其转换为查找哈希表，该表根据可执行文件名称查询完整路径：

```powershell
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

$lookup = Get-ItemProperty -Path $key |
    Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore |
    Where-Object { $_ } |
    Group-Object -Property {
$_.Replace('"','').Split('\')[-1].ToLower()
    } -AsHashTable -AsString
```

您现在可以列出所有已注册的应用程序的清单：

```powershell
PS> $lookup.Keys
outlook.exe
winword.exe
snagit32.exe
7zfm.exe
msoasb.exe
...
```

或者您可以可以将可执行文件的路径转换为它的真实路径：

```powershell
PS> $lookup['excel.exe']
C:\Program Files (x86)\Microsoft Office\Root\Office16\EXCEL.EXE
```

<!--本文国际来源：[Listing Installed Applications (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-installed-applications-part-1)-->

