---
layout: post
date: 2023-04-21 00:00:12
title: "PowerShell 技能连载 - 常见陷阱和奇怪结果：比较运算符"
description: 'PowerTip of the Day - Common Pitfall and Strange Results: Comparison Operator'
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
你能发现下面代码中的错误吗？

```powershell
$result = 'NO'

if ($result = 'YES')
{
    'Result: YES'
}
else
{
    'Result: NO'
}
```

无论 `$result` 包含“NO”还是“YES”，它总是返回“Result: YES”。

从其他脚本或编程语言转换到 PowerShell 的人经常遇到这个错误：在 PowerShell 中，“=”是一个独占赋值运算符，而对于比较，您需要使用“`-eq`”。因此，正确的代码（和简单的修复）应该是这样的：

```powershell
$result = 'NO'

if ($result -eq 'YES')
{
    'Result: YES'
}
else
{
    'Result: NO'
}
```

让我们看一下为什么最初的代码总是返回“Result: YES”。

当您意外使用赋值运算符而不是比较运算符时，您将不会得到任何结果，因此这个 NULL 值应该真正评估为 `$false`，并且条件应该始终返回“Result: NO”。然而，情况恰恰相反。

这是由于另一个PowerShell鲜为人知的怪异之处：当您分配一个值并将分配放在大括号中时，分配也将被返回。最初错误的代码将使用实际响应于赋值值的条件。

每当您向$result（所有都被解释为FALSE）分配0、''、$false 或 $null 时，代码都会返回“Result: NO”。任何其他赋值都会返回“Result: YES”。

所有这些令人困惑的行为只是因为用户肌肉记忆使用了操作符“=”而实际上需要“-eq”操作符。

<!--本文国际来源：[Common Pitfall and Strange Results: Comparison Operator](https://blog.idera.com/database-tools/powershell/powertips/common-pitfall-and-strange-results-comparison-operator/)-->

