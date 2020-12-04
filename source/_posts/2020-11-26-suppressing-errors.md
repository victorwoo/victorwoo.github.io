---
layout: post
date: 2020-11-26 00:00:00
title: "PowerShell 技能连载 - 禁止错误提示"
description: PowerTip of the Day - Suppressing Errors
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 cmdlet，禁止错误提示似乎很容易：只需添加 `–ErrorAction Ignore` 参数。

但是，事实证明，这并不能消除所有错误。它仅禁止 cmdlet 选择处理的错误。特别是与安全相关的异常仍然显示。

如果要禁止所有错误提示，可以通过在命令尾部 `2>$null` 将异常传递给 null：

    PS> Get-Service foobar 2>$null

这适用于所有命令甚至原生方法的调用。只需将代码括在大括号中，然后通过 `＆` 调用运算符来进行调用：

```powershell
PS> [Net.DNS]::GetHostEntry('notPresent')
MethodInvocationException: Exception calling "GetHostEntry" with "1" argument(s): "No such host is known."

PS> & {[Net.DNS]::GetHostEntry('notPresent')} 2>$null

PS>
```

<!--本文国际来源：[Suppressing Errors](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/suppressing-errors)-->

