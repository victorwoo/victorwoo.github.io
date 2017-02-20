layout: post
date: 2017-02-14 16:00:00
title: "PowerShell 技能连载 - 检测有问题的 Execution Policy Settings"
description: PowerTip of the Day - Identifying Problematic Execution Policy Settings
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell 用执行策略 (execution policy) 来决定是否执行某个脚本。实际上定义执行策略可以定义 5 种作用域。要查看这所有五种情况，请使用这个命令：

```powershell
PS C:\> Get-ExecutionPolicy -List

    Scope ExecutionPolicy
    ----- ---------------
MachinePolicy       Undefined
UserPolicy       Undefined
    Process       Undefined
CurrentUser    RemoteSigned
LocalMachine       Undefined
```

要确定生效的设置，PowerShell 会从上到下遍历这些作用域，然后取第一个非 "`Undefined`" 设置。如果所有作用域都设置成 "`Undefined`"，那么 PowerShell 将使用 "`Restricted`" 设置，并且阻止脚本执行。这是缺省的行为。

请永远保持 "`MachinePolicy`" 和 "`UserPolicy`" 作用域设置成 "`Undefined`"。这些作用域智能由组策略集中设置。如果它们设置成任何非 "`Undefined`" 的值，用户则无法改变生效的设置。

有些公司使用这种方式来限制脚本的执行，它们用 execution policy 作为安全的屏障——而它并不是。"`LocalMachine`" 作用域种的 Execution policy 永远应该是缺省值，而不应该强迫一个用户的设置。

如果 "`MachinePolicy`" 或 "`UserPolicy`" 有设置值，在 PowerShell 5 以及以下版本也有个 bug，可能会导致启动一个 PowerShell 脚本时延迟近 30 秒。这个延迟可能是内部导致的：PowerShell 使用 WMI 确定当前运行的进程，来决定一个 PowerShell 脚本是否作为一个组策略执行，而这种实现方式可能会造成过多的延迟。

所以如果您看见 "`MachinePolicy`" 或 "`UserPolicy`" 作用域中的设置不是 "`Undefined`"，您应该和 Active Directory 团队商量并和他们解释执行策略的目的：这是一个偏好设置，而不是一个限制设置。应该使用其它技术，例如 "“Software Restriction Policy" 来安全地限制脚本的使用。

<!--more-->
本文国际来源：[Identifying Problematic Execution Policy Settings](http://community.idera.com/powershell/powertips/b/tips/posts/identifying-problematic-execution-policy-settings)
