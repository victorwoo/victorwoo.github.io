---
layout: post
date: 2017-09-06 00:00:00
title: "PowerShell 技能连载 - 查找所有 UAC 提权记录"
description: PowerTip of the Day - Finding UAC Elevations
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
Windows 的“安全”日志包含了丰富的审计信息。默认情况下，它记录了所有的提权请求。当您以管理员身份运行一个应用程序的时候，就会产生一条记录。

要获取您机器上提权的记录列表，请试试以下代码：

```powershell
#requires -RunAsAdministrator

function Get-ElevationInfo
{
  param
  (
    [DateTime]$Before,
    [DateTime]$After,
    [string[]]$ComputerName,
    $User = '*',
    $Privileges = '*',
    $Newest = [Int]::MaxValue
  )

  $null = $PSBoundParameters.Remove('Privileges')
  $null = $PSBoundParameters.Remove('User')
  $null = $PSBoundParameters.Remove('Newest')



  Get-EventLog -LogName Security -InstanceId 4672 @PSBoundParameters |
  ForEach-Object {
    [PSCustomObject]@{
      Time = $_.TimeGenerated
      User = $_.ReplacementStrings[1]
      Domain = $_.ReplacementStrings[2]
      Privileges = $_.ReplacementStrings[4]
    }
  } |
  Where-Object Path -like $Privileges |
  Where-Object User -like $User |
  Select-Object -First $Newest
}

Get-ElevationInfo -User pshero* -Newest 2 |
Out-GridView
```

`Get-ElevationInfo` 查询 ID 为 4672 的系统日志。安全信息是受保护的，所以只有管理员账户才能执行这段代码。这是为什么这段代码使用 `#requires` 来防止非管理员执行这段代码的原因。

这个函数也利用了 `$PSBoundParameters` 哈希表。这个哈希表包含了用户传入的所有参数。只有一部分信息需要传递给 `Get-EventLog` 命令，所以用于其他参数需要从哈希表中移除。这样，用户可以只传递 `Before`、`After` 和 `ComputerName` 给 `Get-EventLog` 命令。

接下来，处理事件信息。所有相关的信息都可以在 `ReplacementStrings` 属性中找到。这个属性是一个数组。正如结果所展示的那样，ID 为 4672 的事件，第二个（下标为 1）元素为用户名，第三个（下标为 2）元素为域名，第五个（下标为 4）列出获取到的安全特权。

<!--more-->
本文国际来源：[Finding UAC Elevations](http://community.idera.com/powershell/powertips/b/tips/posts/finding-uac-elevations)
