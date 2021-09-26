---
layout: post
date: 2021-09-20 00:00:00
title: "PowerShell 技能连载 - 识别本地管理员帐户"
description: PowerTip of the Day - Identifying Local Administrator Account
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 计算机上有一些默认帐户，例如本地 "Administrator" 帐户。虽然默认情况下此帐户存在，但其名称可以因文化而异，并且其名称也可以重命名。

要始终识别本地管理员帐户而不管其名称如何，请按 SID（安全标识符）搜索本地帐户。本地管理员帐户 SID 始终以 "S-1-5-" 开头并使用 RID "-500"：

```powershell
PS> Get-Localuser | Where-Object Sid -like 'S-1-5-*-500'

Name          Enabled Description
----          ------- -----------
Administrator False   Built-in account for administering the computer/domain
```

<!--本文国际来源：[Identifying Local Administrator Account](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-local-administrator-account)-->

