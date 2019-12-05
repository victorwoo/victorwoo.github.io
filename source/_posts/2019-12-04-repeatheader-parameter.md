---
layout: post
date: 2019-12-04 00:00:00
title: "PowerShell 技能连载 - -RepeatHeader 参数"
description: PowerTip of the Day - -RepeatHeader Parameter
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一个不太为人所知的参数：`RepeatHeader`，它是做什么用的？

假设您希望分页显示结果（在命令行中有效，而在 PowerShell ISE 中无效）：

```powershell
PS> Get-Process | Out-Host -Paging
```

结果输出时每页会暂停，直到按下空格键。然而，列标题只显示在第一页中。

以下是更好的输出形式：

```powershell
PS> Get-Process | Format-Table -RepeatHeader | Out-Host -Paging
```

现在，每一页都会重新显示列标题。`-RepeatHeader` 在所有的 `Format-*` cmdlet 中都有效。再次提醒，这个技巧只在基于控制台的 PowerShell 宿主中有效，并且在 PowerShell ISE 中无效。原因是：PowerShell ISE 没有固定的页大小，所以它无法知道一页什么时候结束。

<!--本文国际来源：[-RepeatHeader Parameter](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/repeatheader-parameter)-->

