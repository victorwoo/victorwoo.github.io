---
layout: post
date: 2021-02-18 00:00:00
title: "PowerShell 技能连载 - 跨平台的 Out-GridView"
description: PowerTip of the Day - Cross-Platform Out-GridView
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Out-GridView` 是最常用的 cmdlet 之一，它会打开一个通用选择对话框。不幸的是，PowerShell 只能在 Windows 操作系统上显示图形元素，例如窗口。在 Linux 和 macOS 上，图形 cmdlet（例如 `Out-GridView`）不可用。

您可能想尝试使用新的基于文本的 `Out-ConsoleGridView`。此 cmdlet 仅适用于PowerShell 7（在Windows PowerShell中不起作用）。像这样安装它：

```powershell
Install-Module -Name Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser
```

安装完成后，在许多情况下，您现在可以轻松地将 `Out-GridView` 替换为 `Out-ConsoleGridView`，并享受类似于旧版 Norton Commander 的基于文本的选择对话框。这是旧版 Windows PowerShell 脚本，无法在 Linux 上使用：

```powershell
Get-Process |
Where-Object MainWindowHandle |
Select-Object -Property Name, Id, Description |
Sort-Object -Property Name |
Out-GridView -Title 'Prozesse' -OutputMode Multiple |
Stop-Process -WhatIf
```

只需将 `Out-GridView` 替换为 `Out-ConsoleGridView`，便一切就绪。

<!--本文国际来源：[Cross-Platform Out-GridView](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cross-platform-out-gridview)-->

