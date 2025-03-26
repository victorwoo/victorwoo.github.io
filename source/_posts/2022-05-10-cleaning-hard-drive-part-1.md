---
layout: post
date: 2022-05-10 00:00:00
title: "PowerShell 技能连载 - 清理硬盘（第 1 部分）"
description: PowerTip of the Day - Cleaning Hard Drive (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`cleanmgr.exe` 是 Windows 自带的一个古老的工具，可以清除您的硬盘驱动器。

该工具可以删除各种垃圾数据，有时会删除许多 GB 的空间。对于 PowerShell 来说，它更有趣的地方在于支持自动化。

为了自动化清理磁盘，首先您需要启动具有管理员特权的 PowerShell（如果没有，不会提出错误，但是您的清理选择无法正确保存）。接下来，选择一个随机数，例如 5388，然后执行以下代码：

```powershell
PS> cleanmgr.exe /sageset:5388
```

这将打开一个对话框窗口，您可以在其中选择下一步要执行的清理任务。检查所有适用的项目，然后单击“确定”。

现在，这些选择存储在您的自定义 ID 5388（或您选择的其他位置）下的 Windows 注册表中。 通过再次运行命令检查：对话框应再次打开并记住您的选择。如果对话框不记得您的选择，则可能没有使用管理员特权运行它。

要自动化磁盘清理，请使用参数 `/sagerun` 而不是 `/sageset` 运行命令，然后使用相同的 ID 号：

```powershell
PS> cleanmgr /sagerun:5388
```

现在，清理程序无人值守地执行清理操作，因此这可能是某些情况下清理磁盘的最佳方法。

请注意，对话框显示清理进度，当前用户可以通过单击“取消”来中止清理。不过，无法隐藏此对话框。

<!--本文国际来源：[Cleaning Hard Drive (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-hard-drive-part-1)-->

