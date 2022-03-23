---
layout: post
date: 2022-03-11 00:00:00
title: "PowerShell 技能连载 - 为文件夹快速打开 PowerShell"
description: PowerTip of the Day - Quickly Open PowerShell for Folder
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 Windows 资源管理器中导航到文件夹时，您可以轻松打开传统的 cmd 或 PowerShell 控制台，并将当前文件夹设置为当前路径。

只需单击 Windows 资源管理器窗口中的地址栏然后输入 `cmd`，`powershell` 或 `pwsh`，然后按 ENTER 键。

`cmd` 命令将打开经典命令行，`powershell` 命令将打开 Windows PowerShell 控制台，`pwsh` 命令将打开 PowerShell 7 控制台（如果已安装）。

仅当存在具有命令名称的文件夹时，此技巧才会失败。如果您打开 Documents 文件夹，单击地址栏，然后输入 "powershell"，那么只有在任何地方都没有名为 "PowerShell" 的子文件夹时，按下 ENTER 键才会打开一个 PowerShell 控制台。因为如果有，资源管理器只会打开此文件夹。

要解决此问题，只需将 ".exe" 添加到在地址栏中输入的命令中。"powershell.exe" 始终打开 Windows PowerShell 控制台，并将当前资源管理器的文件夹设置为默认路径。

<!--本文国际来源：[Quickly Open PowerShell for Folder](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/quickly-open-powershell-for-folder)-->

