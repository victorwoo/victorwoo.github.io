---
layout: post
date: 2019-07-03 00:00:00
title: "PowerShell 技能连载 - 覆盖 Out-Default（第 1 部分）"
description: PowerTip of the Day - Overriding Out-Default (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Out-Default` 是一个隐藏的 PowerShell cmdlet，它在每个命令执行结束时被调用，并且将结果输出到控制台。您可以将这个函数覆盖为自己的版本，例如忽略所有输出，或输出一条“机密”消息：

```powershell
function Out-Default
{
    'SECRET!'
}
```

以下是移除自定义覆盖函数的方法：

```powershell
PS C:\> del function:Out-Default
```

<!--本文国际来源：[Overriding Out-Default (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/overriding-out-default-part-1)-->

