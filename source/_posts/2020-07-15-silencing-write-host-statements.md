---
layout: post
date: 2020-07-15 00:00:00
title: "PowerShell 技能连载 - 禁止 Write-Host 语句输出"
description: PowerTip of the Day - Silencing Write-Host Statements
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Write-Host` 是将信息输出给用户的非常有用的 cmdlet，因为此输出不能被丢弃：

```powershell
function Invoke-Test
{
  "Regular Output"
  Write-Host "You always see me!"
}

# both show
Invoke-Test

# Write-Host still shows
$result = Invoke-Test
```

不过从 PowerShell 5开始，引擎发生了悄然的变化。`Write-Host` 产生的输出现在也由流系统控制，并且 `Write-Host` 与 `Write-Information` 共享新的信息流。

如果要隐藏 `Write-Host` 发出的消息，只需将 #6 流重定向到 `$null`：

```powershell
PS> $result = Invoke-Test 6>$null
```

有关流和重定向的更多信息，请访问 [https://powershell.one/code/9.html](https://powershell.one/code/9.html)。

<!--本文国际来源：[Silencing Write-Host Statements](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/silencing-write-host-statements)-->

