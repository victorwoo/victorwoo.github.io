---
layout: post
date: 2019-07-11 00:00:00
title: "PowerShell 技能连载 - 检测按键"
description: PowerTip of the Day - Detecting Key Presses
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 可能需要知道当前是否按下了给定的键。这样，您的配置文件脚本就可以在 PowerShell 启动期间基于您所按下的键执行一些操作。例如，在启动 PowerShell 时按住 CTRL 键，配置文件脚本可以预加载某些模块或连接到服务器。

以下是 Powershell 检测按键的方法：

```powershell
# this could be part of your profile script

Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore

# assume the script is doing something
# (so you can get ready and press left Ctrl!)
Start-Sleep -Seconds 2

# choose the key you are after
$key = [System.Windows.Input.Key]::LeftCtrl
$isCtrl = [System.Windows.Input.Keyboard]::IsKeyDown($key)

if ($isCtrl)
{
    'You pressed left CTRL, so I am now doing extra stuff'
}
```

<!--本文国际来源：[Detecting Key Presses](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/detecting-key-presses)-->

