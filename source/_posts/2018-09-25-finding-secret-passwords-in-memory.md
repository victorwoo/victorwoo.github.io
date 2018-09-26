---
layout: post
date: 2018-09-25 00:00:00
title: "PowerShell 技能连载 - 查找内存中的密码"
description: PowerTip of the Day - Finding Secret Passwords in Memory
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
有些脚本执行后可能会留下敏感信息。这可能是偶然发生，当使用全局作用域，或是用户通过 "dot-sourced" 调用函数和命令。其中一些变量可能包含对于黑客十分感兴趣的数据，比如用户名和密码。

以下是一个快速的测试，检查内存中的所有变量并查找凭据，然后返回变量和用户名，以及明文形式的密码：

```powershell
    Get-Variable | 
        Where-Object Value -is [System.Management.Automation.PSCredential] |
        ForEach-Object {
            [PSCustomObject]@{
                Variable = '$' + $_.Name
                User = $_.Value.UserName
                Password = $_.Value.GetNetworkCredential().Password
            }
        }
```

要测试执行，请使用凭据创建一个变量：

```powershell
PS> $test = Get-Credential
cmdlet Get-Credential at command pipeline position 1
Supply values for the following parameters:
```

然后，运行以上代码在内存中查找变量。

如果您想最小化风险，请确使用 `Remove-Variable` 命令手工保移除了所有变量。通常情况下，您可以信任自动垃圾收集，但是当包含敏感数据是，攻击者可能会使用多种方法防止变量被自动回收。当您人工移除后，就安全了。

<!--more-->
本文国际来源：[Finding Secret Passwords in Memory](http://community.idera.com/powershell/powertips/b/tips/posts/finding-secret-passwords-in-memory)
