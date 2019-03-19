---
layout: post
date: 2017-10-03 00:00:00
title: "PowerShell 技能连载 - PowerShell 2 接近过期"
description: PowerTip of the Day - PowerShell 2 Now Considered Deprecated
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Microsoft 刚刚宣布 PowerShell 2 很快将会标记为“已过期的”。它在一段时间内仍然可以用，但是友情提醒您最好不要使用它，并请关注 PowerShell 5。

PowerShell 2 是 Windows 7 缺省带的 PowerShell。但即使在现代的操作系统中，PowerShell 2 仍然存在。让我们看看 PowerShell 2 对你的系统有多大影响。

以下这行代码返回当前 PowerShell 的版本号：

```powershell
PS> $PSVersionTable.PSVersion.Major
5
```

如果显示的版本号低于 5，那么您需要检查升级的策略。PowerShell 5 是 PowerShell 最新的版本，并且 Windows 7 和 Server 2008 R2 以上的版本都可以通过更新获得它。通常没有任何理由运行 PowerShell 5 以下的版本，除非在那些运行着过时的可能依赖于更早版本的 PowerShell 的软件组件的服务器上。

这行代码将告诉您 PowerShell 2 子系统是否仍然存在：

```powershell
PS> powershell -version 2.0
Windows PowerShell
Copyright (C) 2009 Microsoft Corporation. All rights reserved.

PS>
```

如果这行代码运行后没有报任何错，并且启动了一个版权为“2009”的 PowerShell，那么说明 Windows 功能 PowerShell 2 还是启用状态。这不太好。这个功能原本是作为需要 PowerShell 2 的脚本的降级环境。现在该子系统基本不再使用，而变成一个恶意脚本代码的攻击维度，因为PowerShell 2 比起 PowerShell 5 缺少一些安全和保护功能。例如，相比于 PowerShell 5，运行在在 PowerShell 2 子系统中的恶意代码不会在反病毒引擎中有效地记录和报告。

除非有很强的理由保留 PowerShell 2，正常情况下您应该移除它。在客户端操作系统中，请打开控制面板，程序和功能，“启用或关闭 Windows 功能”，然后反选“Windows PowerShell 2.0”。

对于服务器系统，请使用 `Remove-WindowsFeature`。

<!--本文国际来源：[PowerShell 2 Now Considered Deprecated](http://community.idera.com/powershell/powertips/b/tips/posts/powershell-2-now-considered-deprecated)-->
