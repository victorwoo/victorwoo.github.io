---
layout: post
date: 2017-12-18 00:00:00
title: "PowerShell 技能连载 - 覆盖 Execution Policy 设置"
description: PowerTip of the Day - Execution Policy Override
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果 PowerShell 不允许执行脚本，您可能需要先允许脚本执行，例如：

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

当 execution policy 是在组策略中定义时，这样操作不会起作用，因为组策略设置优先级更高：

```powershell
PS C:\> Get-ExecutionPolicy -List

        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy      Restricted
    UserPolicy       Undefined
        Process          Bypass
    CurrentUser          Bypass
    LocalMachine       Undefined
```

在这种情况下，您可以将 PowerShell 内置的授权管理器替换成一个新的。只需要运行以下代码，PowerShell 将总是允许在指定的会话中执行脚本：

```powershell
$context = $executioncontext.gettype().getfield('_context','nonpublic,instance').getvalue($executioncontext);
$field = $context.gettype().getfield('_authorizationManager','nonpublic,instance');
$field.setvalue($context,(new-object management.automation.authorizationmanager 'Microsoft.PowerShell'))
```

<!--本文国际来源：[Execution Policy Override](http://community.idera.com/powershell/powertips/b/tips/posts/execution-policy-override)-->
