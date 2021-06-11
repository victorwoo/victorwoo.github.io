---
layout: post
date: 2021-06-08 00:00:00
title: "PowerShell 技能连载 - 评估事件日志数据（第 3 部分）"
description: PowerTip of the Day - Evaluating Event Log Data (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们了解了 `Get-WinEvent` 以及如何使用计算属性直接访问附加到每个事件的“属性”，而不必对事件消息进行文本解析。

例如，下面的代码通过从“属性”中找到的数组中提取已安装更新的名称来生成已安装更新列表：

```powershell
$software = @{
    Name = 'Software'    Expression = { $_.Properties[0].Value  }
}Get-WinEvent -FilterHashTable @{
    Logname='System'    ID=19    ProviderName='Microsoft-Windows-WindowsUpdateClient'} | Select-Object -Property TimeCreated, $software
```

这个概念一般适用于所有事件类型，您唯一的工作就是找出哪些信息包含在哪个数组索引中。让我们来看一个更复杂的事件类型，它包含的不仅仅是一条信息：

```powershell
$LogonType = @{
    Name = 'LogonType'    Expression = { $_.Properties[8].Value }
}$Process = @{
    Name = 'Process'    Expression = { $_.Properties[9].Value }
}$Domain = @{
    Name = 'Domain'    Expression = { $_.Properties[5].Value }
}$User = @{
    Name = 'User'    Expression = { $_.Properties[6].Value }
}$Method = @{
    Name = 'Method'    Expression = { $_.Properties[10].Value }
}Get-WinEvent -FilterHashtable @{
    LogName = 'Security'    Id = 4624    } | Select-Object -Property TimeCreated, $LogonType, $Process, $Domain, $User, $Method
```

在这里，`Get-WinEvent` 从安全日志中读取 ID 为 4624 的所有事件。这些事件代表登录。由于事件位于安全日志中，因此您需要本地管理员权限才能运行代码。

`Select-Object` 仅返回 `TimeCreated` 属性。所有剩余的属性都被计算出来，基本上都是一样的：它们从所有事件日志条目对象中找到的“属性”数组中提取一些信息。

事实证明，登录的用户名可以在该数组的索引 6 中找到，登录类型可以在数组索引 8 中找到。

将代码包装到一个函数中后，现在可以很容易地对记录的登录事件进行复杂的查询：

```powershell
function Get-LogonInfo{
  $LogonType = @{
    Name = 'LogonType'    Expression = { $_.Properties[8].Value }
  }

  $Process = @{
    Name = 'Process'    Expression = { $_.Properties[9].Value }
  }

  $Domain = @{
    Name = 'Domain'    Expression = { $_.Properties[5].Value }
  }

  $User = @{
    Name = 'User'    Expression = { $_.Properties[6].Value }
  }

  $Method = @{
    Name = 'Method'    Expression = { $_.Properties[10].Value }
  }

  Get-WinEvent -FilterHashtable @{
    LogName = 'Security'    Id = 4624  } | Select-Object -Property TimeCreated, $LogonType, $Process, $Domain, $User, $Method}Get-LogonInfo |  Where-Object Domain -ne System |  Where-Object User -ne 'Window Manager' |  Select-Object -Property TimeCreated, Domain, User, Method
```

结果类似于：

    TimeCreated         Domain                  User             Method
    -----------         ------                  ----             ------
    06.05.2021 11:46:04 RemotingUser2           DELL7390         Negotiate
    05.05.2021 19:20:16 tobi.weltner@-------.de MicrosoftAccount Negotiate
    05.05.2021 19:20:06 UMFD-1                  Font Driver Host Negotiate
    05.05.2021 19:20:05 UMFD-0                  Font Driver Host Negotiate

<!--本文国际来源：[Evaluating Event Log Data (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/evaluating-event-log-data-part-3)-->

