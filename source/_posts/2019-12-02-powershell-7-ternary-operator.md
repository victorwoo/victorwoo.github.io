---
layout: post
date: 2019-12-02 00:00:00
title: "PowerShell 技能连载 - PowerShell 7 中的三元操作符"
description: PowerTip of the Day - PowerShell 7 Ternary Operator
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 7 中，语言增加了一个新的操作符，引发了大量的辩论。基本上，您不必要使用它，但是有编程背景的用户会喜欢它。

直到现在，要创建一个条件判断，总是需要写许多代码。例如，要查询脚本运行环境是 32 位还是 64 位，您可以像这样查询指针的长度：

```powershell
if ([IntPtr]::Size -eq 8)
{
    '64-bit'
}
else
{
    '32-bit'
}
```

三元操作符可以大大缩短代码：

```powershell
[IntPtr]::Size -eq 8 ? '64-bit' : '32-bit'
```

本质上，三元操作符 ("`?`") 是标准 "`if`" 条件判断的缩写。它对所有取值为 `$true` 或 `$false` 的表达式有效。如果该表达式的执行结果是 `$true`，那么执行 "`?`" 之后的表达式。如果该表达式的执行结果是 `$false`，那么执行 "`:`" 之后的表达式。

如果您安装了 PowerShell 7 preview 版，请确保您更新到了最新版本，才能确保使用三元操作符。它并不是 PowerShell 7 preview 版本的一部分。

<!--本文国际来源：[PowerShell 7 Ternary Operator](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/powershell-7-ternary-operator)-->

