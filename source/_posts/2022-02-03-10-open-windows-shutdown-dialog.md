---
layout: post
date: 2022-02-03 00:00:00
title: "PowerShell 技能连载 - 打开关闭 Windows 的对话框"
description: PowerTip of the Day - Open Windows Shutdown Dialog
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是打开关闭 Windows 对话框的一行代码：

```powershell
(New-Object -ComObject Shell.Application).ShutdownWindows()
```

使用此行代码，它变成了名为 "bye" 的新命令：

```powershell
function bye { (New-Object -ComObject Shell.Application).ShutdownWindows() }
```

如果将此行放在 `$profile` 中的自动配置文件 (start) 脚本中（可能需要先创建该文件），则完成脚本时，您现在可以简单地输入 "bye" 以关闭您的 Windows 会话。

<!--本文国际来源：[Open Windows Shutdown Dialog](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/10-open-windows-shutdown-dialog)-->

