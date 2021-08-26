---
layout: post
date: 2021-08-23 00:00:00
title: "PowerShell 技能连载 - 显示警告对话框（第 2 部分）"
description: PowerTip of the Day - Displaying Warning Dialog (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们创建了新的快捷方式文件，您已经看到 `CreateShortcut()` 方法如何提供方法来控制快捷方式的几乎所有细节。这是在桌面上创建 PowerShell 快捷方式的代码：

这个技能可以帮助您始终在其他窗口的顶部显示对话框。为此，下面的代码创建了一个新的虚拟窗口，并确保该窗口位于所有其他窗口的顶部。然后，此窗口用作弹出对话框的父级：

```powershell
Add-Type -AssemblyName  System.Windows.Forms
$message = 'Your system will shutdown soon!'
$title = 'Alert'

# create a dummy window
$form = [System.Windows.Forms.Form]::new()
$form.TopMost = $true

# use the dummy window as parent for the dialog so it appears on top of it
[System.Windows.Forms.MessageBox]::Show($form, $message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)

# don't forget to dispose the dummy window after use
$form.Dispose()
```

<!--本文国际来源：[Displaying Warning Dialog (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/displaying-warning-dialog-part-2)-->

