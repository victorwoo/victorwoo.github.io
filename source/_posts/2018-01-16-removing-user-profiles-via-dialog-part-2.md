---
layout: post
date: 2018-01-16 00:00:00
title: "PowerShell 技能连载 - 通过对话框移除用户配置文件（第二部分）"
description: PowerTip of the Day - Removing User Profiles Via Dialog (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用一个用一个网格视图窗口显示所有可用的用户配置文件，并且可以选中一条并删除：

```powershell
#requires -RunAsAdministrator

Get-WmiObject -ClassName Win32_UserProfile -Filter "Special=False AND Loaded=False" |
    Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
    Out-GridView -Title "Select User Profile" -OutputMode Single |
    ForEach-Object {
        # uncomment the line below to actually remove the selected user profile!
        #$_.Delete()
    }
```

它可以像预期中的那样工作，网格视图窗口显示许多不需要的信息。如果您想用它作为一个服务桌面程序，您肯定只希望显示其中的一部分信息。

您当然可以在将结果通过管道导出到网格视图窗口之前使用 `Select-Object` 来控制显示哪些信息。然而，这将会改变数据的类型，而且这将导致无法访问对象的一些成员，例如使用 `Delete()` 来删除用户配置文件。

所以这是一个更普遍的问题：

如何用网格视图窗口来显示自定义数据，而当用户选择一条记录时，返回原始的对象？

一个简单的方法是用 `Group-Object` 来创建一个哈希表：将原始的数据通过类似 "UserName" 等属性来分组。然后，在网格视图窗口中显示哈希表的键。当用户选择了一个对象时，将选中的作为键，来访问哈希表中的原始对象：

```powershell
#requires -RunAsAdministrator

$hashTable = Get-WmiObject -ClassName Win32_UserProfile -Filter "Special=False AND Loaded=False" |
    Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
    Group-Object -Property UserName -AsHashTable -AsString

$hashTable.Keys |
    Sort-Object |
    Out-GridView -Title "Select User Profile" -OutputMode Single |
    ForEach-Object {
        # uncomment the line below to actually remove the selected user profile!
        # $hashTable[$_].Delete()
```

现在这个工具使用起来方便多了：网格视图窗口只显示用户名，而当您选择了一项后，可以获取到原始对象，进而做删除操作。

<!--本文国际来源：[Removing User Profiles Via Dialog (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/removing-user-profiles-via-dialog-part-2)-->
