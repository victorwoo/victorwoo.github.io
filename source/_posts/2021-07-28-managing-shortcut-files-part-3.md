---
layout: post
date: 2021-07-28 00:00:00
title: "PowerShell 技能连载 - 管理快捷方式文件（第 3 部分）"
description: PowerTip of the Day - Managing Shortcut Files (Part 3)
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

但是，代码不能做的一件事是启用快捷方式文件的管理员权限，因此双击快捷方式图标会自动提升 LNK 文件启动的 PowerShell。

要启用管理员权限，您必须右键单击新创建的快捷方式文件并手动选择“属性”，然后手动检查相应的对话框。

或者，您需要知道 URL 文件的二进制格式，并通过 PowerShell 翻转这些位。下面的代码将你刚刚在桌面上创建的快捷方式文件变成了一个自动提升的文件：

```powershell
# launch LNK file as Administrator
# THIS PATH MUST EXIST (use previous script to create the LNK file or create one manually)
$path = [Environment]::GetFolderPath('Desktop') | Join-Path -ChildPath 'myLink.lnk'
# read LNK file as bytes...
$bytes = [System.IO.File]::ReadAllBytes($path)
# flip a bit in byte 21 (0x15)
$bytes[0x15] = $bytes[0x15] -bor 0x20
# update the bytes
[System.IO.File]::WriteAllBytes($path, $bytes)
```

当您现在双击 LNK 文件时，它会自动提升权限。将位翻转回原位以从任何 LNK 文件中删除管理员权限功能：

```powershell
$bytes[0x15] = $bytes[0x15] -band -not 0x20
```
<!--本文国际来源：[Managing Shortcut Files (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-shortcut-files-part-3)-->

