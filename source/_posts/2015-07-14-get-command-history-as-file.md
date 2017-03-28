layout: post
date: 2015-07-14 11:00:00
title: "PowerShell 技能连载 - 将命令历史保存到文件"
description: PowerTip of the Day - Get Command History as File
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
随着 PowerShell 3.0 及以上脚本发布的 PowerShell ISE 内置编辑器可以支持定制，并且可以增加自己的菜单项。

当您运行以下代码时，您会发现在“附加工具”菜单中会多出一个“Get Command History”子菜单，也可以通过 `ALT` + `C` 组合键激活该功能。

这个命令将返回当前的命令行历史（您在当前 ISE 会话中交互式键入的命令）并且将它们拷贝到一个新的 PowerShell 文件中。通过这种方式，可以很轻松地保存互操作的历史。您甚至可以通过这种方式自动创建 PowerShell 脚本：只需要删掉不能用的代码行，只留下能产生预期结果的代码行。

    #requires -Version 3
    $code =
    {
        $text = Get-History |
        Select-Object -ExpandProperty CommandLine |
        Out-String
    
        $file = $psise.CurrentPowerShellTab.Files.Add()
        $file.Editor.Text = $text
    }
    
    $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('Get Command History', $code, 'ALT+C')

<!--more-->
本文国际来源：[Get Command History as File](http://community.idera.com/powershell/powertips/b/tips/posts/get-command-history-as-file)
