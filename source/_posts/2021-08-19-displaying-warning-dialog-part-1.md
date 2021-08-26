---
layout: post
date: 2021-08-19 00:00:00
title: "PowerShell 技能连载 - 显示警告对话框（第 1 部分）"
description: PowerTip of the Day - Displaying Warning Dialog (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是一个显示弹出警告对话框的快速代码示例：

```powershell
Add-Type -AssemblyName  System.Windows.Forms
$message = 'Your system will shutdown soon!'
$title = 'Alert'

[System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
```

这些是可用的按钮样式：

```powershell
PS> [Enum]::GetNames([System.Windows.Forms.MessageBoxButtons])
OK
OKCancel
AbortRetryIgnore
YesNoCancel
YesNo
RetryCancel
```

这些是可用的图标样式：

```powershell
PS> [Enum]::GetNames([System.Windows.Forms.MessageBoxIcon])
None
Hand
Error
Stop
Question
Exclamation
Warning
Asterisk
Information
```

<!--本文国际来源：[Displaying Warning Dialog (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/displaying-warning-dialog-part-1)-->

