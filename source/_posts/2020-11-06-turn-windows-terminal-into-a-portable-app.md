---
layout: post
date: 2020-11-06 00:00:00
title: "PowerShell 技能连载 - 将 Windows Terminal 变成便携式应用程序"
description: PowerTip of the Day - Turn Windows Terminal into a Portable App
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 10 上，任何 PowerShell 用户都可以使用一个很棒的新工具：Windows Terminal。它使您可以同时使用多个 PowerShell 和其他控制台选项卡，并且可以混合使用 Windows PowerShell、PowerShell 7 和 Azure CloudShell 控制台。您可以从 Microsoft Store 安装 Windows Terminal。

与任何应用程序一样，Windows Terminal 由 Windows 管理，可以随时更新。而且它总是“按用户”安装。

如果计划在其中一个控制台中运行冗长的任务或关键业务脚本，则可能需要将该应用程序转换为仅由您自己控制的便携式应用程序。这样，多个用户也可以使用 Windows App。

以下脚本要求您已安装 Windows Terminal 应用程序，并且必须以管理员权限运行代码：

```powershell
#requires -RunAsAdmin

# location to store portable app
$destination = 'c:\windowsterminal'


# search for installed apps...
Get-ChildItem "$env:programfiles\WindowsApps\" |
# pick Windows Terminal...
Where-Object name -like *windowsterminal* |
# find the executable...
Get-ChildItem -Filter wt.exe |
# identify executable versions...
Select-Object -ExpandProperty VersionInfo |
# sort versions...
Sort-Object -Property ProductVersion -Descending |
# pick the latest...
Select-Object -First 1 -ExpandProperty filename |
# get parent folder...
Split-Path |
# dump folder content...
Get-ChildItem |
# copy to destination folder
Copy-Item -Destination $destination -Force

# open folder
explorer $destination

# run portable app
Start-Process -FilePath "$destination\wt.exe"
```

<!--本文国际来源：[Turn Windows Terminal into a Portable App](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/turn-windows-terminal-into-a-portable-app)-->

