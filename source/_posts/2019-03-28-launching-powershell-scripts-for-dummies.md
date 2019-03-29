---
layout: post
date: 2019-03-28 00:00:00
title: "PowerShell 技能连载 - 让新手运行 PowerShell 脚本"
description: PowerTip of the Day - Launching PowerShell Scripts for Dummies
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
假设您要把一段 PowerShell 脚本传给一个没有经验的用户。如何确保对方正确地运行了您的脚本呢？由于操作系统和组策略的限制，有可能并没有一个上下文菜单命令来运行 PowerShell 脚本。这个用户也有可能改变了执行策略设置。

不过有一个非常简单的解决方案：将您的脚本和一个快捷方式一起分发。这个快捷方式包含所有必须的命令行开关，可以通过双击快速执行。您甚至可以为快捷方式分配一个漂亮的图标。然而，您需要一些小技巧来实现。典型的快捷方式使用绝对路径，所以当您将文件发送给客户时这个快捷方式可能无法执行，因为您无法知道客户将把这个文件保存到哪里。诀窍是在快捷方式中使用相对路径。

只需要确保调整了第一行指向希望执行的脚本，然后运行这段代码，就可以了。

```powershell
# specify the path to your PowerShell script
$ScriptPath = "C:\test\test.ps1"

# create a lnk file
$shortcutPath = [System.IO.Path]::ChangeExtension($ScriptPath, "lnk")
$filename = [System.IO.Path]::GetFileName($ScriptPath)

# create a new shortcut
$shell = New-Object -ComObject WScript.Shell
$scut = $shell.CreateShortcut($shortcutPath)
# launch the script with powershell.exe:
$scut.TargetPath = "powershell.exe"
# skip profile scripts and enable execution policy for this one call
# IMPORTANT: specify only the script file name, not the complete path
$scut.Arguments = "-noprofile -executionpolicy bypass -file ""$filename"""
# IMPORTANT: leave the working directory empty. This way, the
# shortcut uses relative paths
$scut.WorkingDirectory = ""
# optinally specify a nice icon
$scut.IconLocation = "$env:windir\system32\shell32.dll,162"
# save shortcut file
$scut.Save()

# open shortcut file in File Explorer
explorer.exe "/select,$shortcutPath"
```

这个快捷方式就放在您的 PowerShell 脚本相邻的位置。它使用相对路径，由于我们保证快捷方式和 PowerShell 脚本放在相同的路径，所以它能够完美地工作——这样您可以将两个文件打包，然后将它们发送给客户。当他解压了文件，快捷方式仍然可以工作。您甚至可以将快捷方式改为想要的名字，例如“双击我执行”。

重要：快捷方式使用相对路径来确保这个解决方案便携化。如果您将快捷方式移动到脚本之外的文件夹，那么该快捷方式显然不能工作。。

<!--本文国际来源：[Launching PowerShell Scripts for Dummies](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/launching-powershell-scripts-for-dummies)-->

