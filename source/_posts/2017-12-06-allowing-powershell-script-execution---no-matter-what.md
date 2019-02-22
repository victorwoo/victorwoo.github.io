---
layout: post
date: 2017-12-06 00:00:00
title: "PowerShell 技能连载 - 强制允许 PowerShell 脚本执行"
description: PowerTip of the Day - Allowing PowerShell Script Execution - No Matter What
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
执行策略 (Execution Policy) 可以禁止脚本执行。它被设计成一个用户的首选项，所以您总是可以改变有关的执行策略。不过，在一些环境下，组策略可以强制改变设置，并且禁止运行脚本。

在这种情况下，您可以考虑重置内部的 PowerShell 授权管理。将它替换为一个缺省的实例以后，您可以忽略之前的执行策略设置，执行 PowerShell 脚本：

```powershell
$context = $executioncontext.gettype().getfield('_context','nonpublic,instance').getvalue($executioncontext); $field = $context.gettype().getfield('_authorizationManager','nonpublic,instance'); $field.setvalue($context,(New-Object management.automation.authorizationmanager 'Microsoft.PowerShell'))
```

请注意，这不是一个安全问题。执行策略的控制权在用户。这并不是一个安全边界。

<!--本文国际来源：[Allowing PowerShell Script Execution - No Matter What](http://community.idera.com/powershell/powertips/b/tips/posts/allowing-powershell-script-execution---no-matter-what)-->
