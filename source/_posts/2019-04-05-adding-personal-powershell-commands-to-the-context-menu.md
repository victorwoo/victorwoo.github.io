---
layout: post
date: 2019-04-05 00:00:00
title: "PowerShell 技能连载 - 向上下文菜单添加个人 PowerShell 命令"
description: PowerTip of the Day - Adding Personal PowerShell Commands to the Context Menu
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可以针对文件类型，例如 PowerShell 文件，添加个人的上下文菜单。当您右键单击一个 .ps1 文件时，将显示这些上下文菜单命令。它们关联到个人账户，并且不需要管理员权限就可以设置。

以下是一个实现的脚本。只需要调整头两个变量：指定上下文菜单中需要出现的命令，以及需要执行的命令行。在这个命令中，使用 "`%1`" 作为右键单击时 PowerShell 脚本路径的占位符：

```powershell
# specify your command name
$ContextCommand = "Open Script with Notepad"
# specify the command to execute. "%1" represents the file path to your
# PowerShell script
$command = 'notepad "%1"'


$baseKey = 'Registry::HKEY_CLASSES_ROOT\.ps1'
$id = (Get-ItemProperty $baseKey).'(Default)'
$ownId = $ContextCommand.Replace(' ','')
$contextKey = "HKCU:\Software\Classes\$id\Shell\$ownId"
$commandKey = "$ContextKey\Command"

New-Item -Path $commandKey -Value $command -Force
Set-Item -Path $contextKey -Value $ContextCommand
```

当您运行这段脚本时，将生成一个名为 "Open Script with Notepad" 的新的上下文菜单命令。您可以利用这个钩子并且设计任何命令，包括 GitHub 或备份脚本。

请注意：当您对 OpenWith 打开方式选择了一个非缺省的命令，那么自定义命令将不会在上下文菜单中显示。这个命令仅当记事本为缺省的 OpenWith 打开方式应用时才出现。

要移除所有上下文菜单扩展，请运行以下代码：

```powershell
$baseKey = 'Registry::HKEY_CLASSES_ROOT\.ps1'
$id = (Get-ItemProperty $baseKey).'(Default)'
$contextKey = "HKCU:\Software\Classes\$id"
Remove-Item -Path $contextKey -Recurse -Force
```

<!--本文国际来源：[Adding Personal PowerShell Commands to the Context Menu](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-personal-powershell-commands-to-the-context-menu)-->

