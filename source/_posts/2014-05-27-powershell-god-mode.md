layout: post
title: "PowerShell 技能连载 - PowerShell 上帝模式"
date: 2014-05-27 00:00:00
description: PowerTip of the Day - PowerShell God Mode
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
若您要运行一个 PowerShell 脚本，您必须通过执行策略的允许。通常您需要使用这行代码来允许脚本运行：

![](/img/2014-05-27-powershell-god-mode-001.png)

然而，如果组策略禁止了脚本执行，那么这行代码将不起作用。在这种情况下，您可以使用这段代码来重新启用允许脚本执行（单个 PowerShell 会话中有效）：

    $context = $executioncontext.GetType().GetField('_context','nonpublic,instance').GetValue($executioncontext)
    $field = $context.GetType().GetField('_authorizationManager','nonpublic,instance')
    $field.SetValue($context,(New-Object Management.Automation.AuthorizationManager 'Microsoft.PowerShell'))

请注意这是一种取巧的办法，它重设了认证管理器，不能保证是否有副作用。使用后果自负。

顺便说一下，这种技术不算是一个安全问题。执行策略通常不是一个安全边界。它并不是设计成用来把坏人挡在外面的。它只是为了保护您自己不做错事。所以无论您是通过 cmdlet 还是通过这段代码来启用脚本执行，您都是对自己执行 PowerShell 代码负责。

<!--more-->
本文国际来源：[PowerShell God Mode](http://powershell.com/cs/blogs/tips/archive/2014/05/27/powershell-god-mode.aspx)
