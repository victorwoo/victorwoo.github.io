---
layout: post
date: 2018-08-14 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 功能（第 1 部分）"
description: PowerTip of the Day - Managing Windows Features (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 10 带来一系列功能，但默认只安装了一个子集。您可以手工打开控制面板查看 Windows 功能。有经验的管理员也会使用 `dism.exe` 命令行工具。

在 PowerShell 中，您可以通过 `Get-WindowsOptionalFeature` 查看 Windows 功能的状态。当您指定了 `-Online` 参数，该 cmdlet 将返回当前可用的功能和它们的状态。

使用 `Where-Object` 命令，您可以容易地过滤结果，并且例如只显示未安装的功能清单：

```powershell
# list all Windows features and their state
Get-WindowsOptionalFeature -Online | Out-GridView

# list only available features that are not yet installed
Get-WindowsOptionalFeature -Online |
    Where-Object State -eq Disabled |
    Out-GridView
```

<!--本文国际来源：[Managing Windows Features (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/managing-windows-features-part-1)-->
