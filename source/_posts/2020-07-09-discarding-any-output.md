---
layout: post
date: 2020-07-09 00:00:00
title: "PowerShell 技能连载 - 忽略（任何）输出"
description: PowerTip of the Day - Discarding (Any) Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
There are (a few) commands in PowerShell that output information to the console no matter what you do. Neither redirection of streams nor assigning to $null will silence such commands, for example:
无论您做什么，PowerShell中都有（少量）命令可将信息输出到控制台。无论流重定向或赋值给 `$null` 都不能禁止这类命令输出，例如：

```powershell
PS> $null = Get-WindowsUpdateLog *>&1
```

即使所有输出流都被丢弃，`Get-WindowsUpdateLog` cmdlet 仍会将大量信息写入控制台。

如果遇到这种情况，最后的方法是暂时禁用内部命令 `Out-Default`，如下所示：

```powershell
# temporarily overwrite Out-Default
function Out-Default {}

# run your code (guaranteed no output)
Get-WindowsUpdateLog

# test any other direct console write
[Console]::WriteLine("Hello")

# restore Out-Default
Remove-Item -Path function:Out-Default
```

<!--本文国际来源：[Discarding (Any) Output](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/discarding-any-output)-->

