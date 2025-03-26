---
layout: post
date: 2022-05-04 00:00:00
title: "PowerShell 技能连载 - 管理蓝牙设备（第 2 部分）"
description: PowerTip of the Day - Managing Bluetooth Devices (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您只是在 Windows 中寻找一种快速的方法来配对和接触配对蓝牙设备，请尝试以下命令：

```powershell
PS> explorer.exe ms-settings-connectabledevices:devicediscovery
```

这将立即弹出一个对话框，显示所有蓝牙设备。只需在 PowerShell 中添加一个函数，因此您不必记住命令，只需要将其放入个人资料脚本中：

```powershell
PS> function Show-Bluetooth { explorer.exe ms-settings-connectabledevices:devicediscovery }

PS> Show-Bluetooth
```

如果您想在桌面放一个蓝牙图标的快捷方式，请尝试以下操作：

```powershell
$desktop = [Environment]::GetFolderPath('Desktop')
$path = Join-Path -Path $desktop -ChildPath 'bluetooth.lnk'
$shell = New-Object -ComObject WScript.Shell
$scut = $shell.CreateShortcut($path)
$scut.TargetPath = 'explorer.exe'
$scut.Arguments = 'ms-settings-connectabledevices:devicediscovery'
$scut.IconLocation = 'fsquirt.exe,0'
$scut.Save()
```

<!--本文国际来源：[Managing Bluetooth Devices (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-bluetooth-devices-part-2)-->

