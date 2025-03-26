---
layout: post
date: 2023-02-22 00:00:55
title: "PowerShell 技能连载 - 研究 ConfirmImpact（第 1 部分：用户视角）"
description: 'PowerTip of the Day - Investigating ConfirmImpact (Part 1: User Perspective)'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中，默认情况下，`$ConfimPreference` 变量设置为 "`High`"。这个设置控制什么？

```powershell
PS> $ConfirmPreference
High
```

任何 PowerShell 命令（二进制 cmdlet 或函数）都可以设置自己的 "`ConfirmImpact`"：允许的值为 `None`、`Low`、`Medium` 和 `High`。`ConfirmImpact` 是一个评估 cmdlet 效果的关键性程度。

默认情况下，当 `$ConfirmImpact` 设置为 "`High`" 时，PowerShell 将在你运行设置了 `ConfirmImpact` 为 `High` 的cmdlet 或函数时自动要求确认（所以你只会在运行像 AD 账户这样不能轻易恢复的东西的 cmdlets 时看到确认对话框弹出）。

作为用户，您可以调整这个风险缓解系统。如果你在一个十分敏感的生产系统上工作，你可能想把 `$ConfirmPreference` 降低到 `Medium` 或甚至 `Low`，以在运行 PowerShell 命令或脚本时获得更多的确认。当设置为 "`Low`"时，即使创建一个新文件夹也会触发自动确认：

```powershell
PS> $ConfirmPreference = 'Low'

PS> New-Item -Path c:\testfolder

Confirm
Are you sure you want to perform this action?
Performing the operation "Create File" on target "Destination:
C:\testfolder".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help
(default is "Y"):
```

同样地，如果你想运行一个脚本而不被自动确认对话框打断，你可以把 `$ConfirmPreference` 设置为 "`None`"，从而关闭这个风险缓解系统。这比为脚本中可能触发确认的每个命令添加 `-Confirm:$false` 参数来手动覆盖自动确认要高效得多。

对 `$ConfirmPreference` 的任何更改都会在关闭当前 PowerShell 会话时恢复为默认值。它们不会自动持久化。如果您想永久更改这些设置，请创建一个配置文件脚本并将所有永久更改添加到这个脚本中。当 PowerShell 启动时，它会自动启动。

这样的配置文件脚本的路径可以在这里找到：

```powershell
PS> $profile.CurrentUserAllHosts
C:\Users\USERNAME\OneDrive\Documents\WindowsPowerShell\profile.ps1
```
<!--本文国际来源：[Investigating ConfirmImpact (Part 1: User Perspective)](https://blog.idera.com/database-tools/powershell/powertips/investigating-confirmimpact-part-1-user-perspective/)-->

