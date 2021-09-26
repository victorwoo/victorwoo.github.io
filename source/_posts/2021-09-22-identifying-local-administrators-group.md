---
layout: post
date: 2021-09-22 00:00:00
title: "PowerShell 技能连载 - 识别本地管理员组"
description: PowerTip of the Day - Identifying Local Administrators Group
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
内置管理员组的任何成员都可以访问广泛的权限，因此检查该组的成员可以成为安全审核的一部分。虽然 "Administrators" 组默认存在，但其名称可能因文化而异，因为它是本地化的。例如，在德国系统中，该组称为 "Administratoren"。

要访问用户组，而无论文化和命名如何变化，请使用其 SID，它始终为 "S-1-5-32-544"：

```powershell
PS> Get-LocalGroup -SID S-1-5-32-544

Name            Description
----            -----------
Administrators  Administrators have complete and unrestricted access to the...
```

同样，要转储具有管理员权限的用户和组列表，请使用 SID 而不是组名：

```powershell
PS> Get-LocalGroupMember -SID S-1-5-32-544
```

<!--本文国际来源：[Identifying Local Administrators Group](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-local-administrators-group)-->

