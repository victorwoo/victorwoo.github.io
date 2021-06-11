---
layout: post
date: 2020-09-01 00:00:00
title: "PowerShell 技能连载 - 删除 Microsoft Teams 缓存数据"
description: PowerTip of the Day - Deleting Microsoft Teams Cache Data
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您使用 Microsoft Teams 进行视频会议，则有时可能需要清理缓存文件并删除驻留在许多子文件夹中的残留数据。

您可以调整上一个示例中的代码来进行清理：

```powershell
# the folder that contains the Microsoft Teams data
$parentFolder = "$env:userprofile\AppData\Roaming\Microsoft\Teams\*"
# list of subfolders that cache data
$list = 'application cache','blob storage','databases','GPUcache','IndexedDB','Local Storage','tmp'

# delete the folders found in the list
Get-ChildItem $parentFolder -Directory |
    Where-Object name -in $list |
    Remove-Item -Recurse -Verbose
```

如果您具有管理员权限，并想为所有用户删除缓存的 Microsoft Teams 数据，请按如下所示更改 `$parentFolder`：

```powershell
$parentFolder = "c:\users\*\AppData\Roaming\Microsoft\Teams\*"
```

<!--本文国际来源：[Deleting Microsoft Teams Cache Data](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/deleting-microsoft-teams-cache-data)-->

