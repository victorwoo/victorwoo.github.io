---
layout: post
date: 2019-01-14 00:00:00
title: "PowerShell 技能连载 - 使用本地化的用户名和组名"
description: PowerTip of the Day - Using Localized User and Group Names
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一行返回由当前用户 SID 解析成名字的代码：

```powershell
([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Translate( [System.Security.Principal.NTAccount]).Value
```

您可能会反对说查询 `$env:username` 环境变量来完成这个目的更容易，的确是这样的。然而在许多场景将 SID 转换为名字很有用。例如，如果您必须知道某个常见账户或组的确切（本地）名字，例如本地的 Administrators 组，只需要使用语言中性的 SID 来翻译它：

```powershell
PS> ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate( [System.Security.Principal.NTAccount]).Value

VORDEFINIERT\Administratoren
```

类似地，以下代码总是列出本地的 Administrators，无论是什么语言的操作系统：

```powershell
$admins = ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate( [System.Security.Principal.NTAccount]).Value
$parts = $admins -split '\\'
$groupname = $parts[-1]

Get-LocalGroupMember -Group $groupname
```

<!--本文国际来源：[Using Localized User and Group Names](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/using-localized-user-and-group-names)-->
