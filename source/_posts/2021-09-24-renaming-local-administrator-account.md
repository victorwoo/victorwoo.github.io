---
layout: post
date: 2021-09-24 00:00:00
title: "PowerShell 技能连载 - 重命名本地管理员账户"
description: PowerTip of the Day - Renaming Local Administrator Account
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
出于安全原因，您可能需要考虑重命名内置的本地管理员帐户。这个账户权限很大，它的名字很容易猜到，所以它是攻击者的常用载体。在重命名此帐户之前，请确保您了解后果：

* 该账户仍能继续工作，但您现在需要使用新分配的名称来登录该帐户。确保没有使用旧的默认名称的自动登录过程
* 重命名帐户不会更改其 SID，因此老练的攻击者仍然可以使用其众所周知的 SID 锁定此帐户

要重命名内置 Administrator 帐户（或任何其他本地帐户），请以管理员权限启动 PowerShell，然后运行以下代码：

```powershell
PS> Rename-LocalUser -Name "Administrator" -NewName "TobiasA"
```

要使用该帐户登录，请使用新分配的名称。通过使用账户的众所周知的 SID，即使您不知道其名称，您仍然可以识别重命名的帐户：

```powershell
PS> Get-Localuser | Where-Object Sid -like 'S-1-5-*-500'

Name    Enabled Description
----    ------- -----------
TobiasA False   Built-in account for administering the computer/domain
```

<!--本文国际来源：[Renaming Local Administrator Account](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/renaming-local-administrator-account)-->

