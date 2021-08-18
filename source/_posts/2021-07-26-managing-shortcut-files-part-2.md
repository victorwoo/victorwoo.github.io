---
layout: post
date: 2021-07-26 00:00:00
title: "PowerShell 技能连载 - 管理快捷方式文件（第 2 部分）"
description: PowerTip of the Day - Managing Shortcut Files (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技巧中，我们创建了新的快捷方式文件，您已经看到 `CreateShortcut()` 方法如何提供方法来控制快捷方式的几乎所有细节。这是在桌面上创建 PowerShell 快捷方式的代码：

```powershell
$path = [Environment]::GetFolderPath('Desktop') | Join-Path -ChildPath 'myLink.lnk'
$scut = (New-Object -ComObject WScript.Shell).CreateShortcut($path)
$scut.TargetPath = 'powershell.exe'
$scut.IconLocation = 'powershell.exe,0'
$scut.Save()
```

这就是全部：在您的桌面上现在有一个新的 PowerShell 快捷方式。调整上面的代码以创建其他应用程序和路径的快捷方式。
<!--本文国际来源：[Managing Shortcut Files (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-shortcut-files-part-2)-->

