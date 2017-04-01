layout: post
title: "PowerShell 技能连载 - 通过按键跳过配置脚本"
date: 2014-06-16 00:00:00
description: PowerTip of the Day - Skipping Profile on Keystroke
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
有些时候您也许希望跳过配置文件中的某些部分。例如，在 ISE 编辑器中，只需要将这段代码加入您的配置脚本（配置脚本的路径可以在通过 `$profile` 变量查看，它也有可能还没有创建）：

    if([System.Windows.Input.Keyboard]::IsKeyDown('Ctrl')) { return }

如果您启动 ISE 编辑器时按住 `CTRL` 键，将跳过您配置脚本中的剩余部分。

或者，您可以这样使用：

    if([System.Windows.Input.Keyboard]::IsKeyDown('Ctrl') -eq $false)
    {
        Write-Warning 'You DID NOT press CTRL, so I could execute things here.'
    }

这样写的话，仅当您启动 ISE 时没有按住 `CTRL` 键时，才会运行花括号内部的代码。

如果您希望这段代码也能用在 PowerShel 控制台中，那么需要加载对应的程序集。这段代码在所有的配置脚本中都通用：

    Add-Type -AssemblyName PresentationFramework
    if([System.Windows.Input.Keyboard]::IsKeyDown('Ctrl') -eq $false)
    {
        Write-Warning 'You DID NOT press CTRL, so I could execute things here.'
    }

<!--more-->
本文国际来源：[Skipping Profile on Keystroke](http://community.idera.com/powershell/powertips/b/tips/posts/skipping-profile-on-keystroke)
