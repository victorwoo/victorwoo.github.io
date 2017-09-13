---
layout: post
date: 2017-09-07 00:00:00
title: "PowerShell 技能连载 - 审计登录事件"
description: PowerTip of the Day - Auditing Logons
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
您是否想知道当您不在的时候是否有人登录过您的 PC？在前一个技能中我们解释了如何从 Windows 安全日志中解析详细的审计信息，假设您拥有管理员权限。

To find out who logged into your PC, try the code below! The function Get-LogonInfo searches for security events with ID 4624. Security information is protected, so you need to be an Administrator to run this code. This is why the code uses a #requires statement that prevents non-Admins from running the code.
要查看谁登录到了您的 PC，请试试以下代码！`Get-LogonInfo` 函数搜索 ID 为 4624 的安全事件。安全信息是受保护的，所以只有管理员账户才能执行这段代码。这是为什么这段代码使用 `#requires` 来防止非管理员执行这段代码的原因。

```powershell
#requires -RunAsAdministrator

function Get-LogonInfo
{
  param
  (
    [Int]$Newest = [Int]::MaxValue,
    [DateTime]$Before,
    [DateTime]$After,
    [string[]]$ComputerName,
    $Authentication = '*',
    $User = '*',
    $Path = '*'
  )

  $null = $PSBoundParameters.Remove('Authentication')
  $null = $PSBoundParameters.Remove('User')
  $null = $PSBoundParameters.Remove('Path')
  $null = $PSBoundParameters.Remove('Newest')
    

  Get-EventLog -LogName Security -InstanceId 4624 @PSBoundParameters |
  ForEach-Object {
    [PSCustomObject]@{
      Time = $_.TimeGenerated
      User = $_.ReplacementStrings[5]
      Domain = $_.ReplacementStrings[6]
      Path = $_.ReplacementStrings[17]
      Authentication = $_.ReplacementStrings[10]

    }
  } |
  Where-Object Path -like $Path |
  Where-Object User -like $User |
  Where-Object Authentication -like $Authentication |
  Select-Object -First $Newest
}


$yesterday = (Get-Date).AddDays(-1)
Get-LogonInfo -After $yesterday |
Out-GridView
```

这个函数也利用了 `$PSBoundParameters` 哈希表。这个哈希表包含了用户传入的所有参数。只有一部分信息需要传递给 `Get-EventLog` 命令，所以用于其他参数需要从哈希表中移除。这样，用户可以只传递 `Before`、`After` 和 `ComputerName` 给 `Get-EventLog` 命令。

接下来，处理事件信息。所有相关的信息都可以在 `ReplacementStrings` 属性中找到。这个属性是一个数组。正如结果所展示的那样，ID 为 4624 的事件，第六个（下标为 5）元素为用户名，第七个（下标为 6）元素为域名，第十八个（下标为 17）列出执行登录操作的可执行程序路径。

物理上的登陆通常是由 `lass` ，即本地安全授权执行的。所以要只查看由人类执行的登录操作，请使用以下代码：

```powershell
$yesterday = (Get-Date).AddDays(-1)
Get-LogonInfo -After $yesterday -Path *\lsass.exe |
Out-GridView
```

<!--more-->
本文国际来源：[Auditing Logons](http://community.idera.com/powershell/powertips/b/tips/posts/auditing-logons)
