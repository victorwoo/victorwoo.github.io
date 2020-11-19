---
layout: post
date: 2020-11-12 00:00:00
title: "PowerShell 技能连载 - 创建图标"
description: PowerTip of the Day - Creating Icons
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们展示了如何微调 "Windows Terminal" 并将新的项目添加到可启动应用程序列表中。如果要为这些条目添加图标，则需要适当的图标文件。

这是一些从可执行文件中提取图标的 PowerShell 代码。您可以在 Windows Terminal 和其他地方使用生成的 ICO 文件。

```powershell
# create output folder
$destination = "c:\icons"
mkdir $destination -ErrorAction Ignore


Add-Type -AssemblyName System.Drawing

# extract PowerShell ISE icon
$path = "$env:windir\system32\windowspowershell\v1.0\powershell_ise.exe"
$name = "$destination\ise.ico"
[System.Drawing.Icon]::ExtractAssociatedIcon($path).ToBitmap().Save($name)

# extract Visual Studio Code icon
$Path = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\code.exe"
$name = "$destination\vscode.ico"
[System.Drawing.Icon]::ExtractAssociatedIcon($path).ToBitmap().Save($name)

explorer $destination
```

<!--本文国际来源：[Creating Icons](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-icons)-->

