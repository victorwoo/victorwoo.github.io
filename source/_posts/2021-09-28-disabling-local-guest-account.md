---
layout: post
date: 2021-09-28 00:00:00
title: "PowerShell 技能连载 - 禁用本地的 Guest 账户"
description: "PowerTip of the Day - Disabling Local “Guest” Account"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows 自带一个名为 "Guest" 的内置帐户。由于此帐户很少使用，最好将它禁用。否则，它的广为人知的名字可能会成为攻击者的目标。

由于帐户名称是本地化的并且可能因文化而略有不同，因此要识别帐户，请使用其 SID：

```powershell
PS> Get-Localuser | Where-Object Sid -like 'S-1-5-*-501'

Name  Enabled Description
----  ------- -----------
Guest False   Built-in account for guest access to the computer/domain
```

如果该帐户尚未禁用（请查看 "`“Enabled”`" 属性），请使用提升权限的 PowerShell 和 `Disable-LocalUser` cmdlet 禁用该帐户。

<!--本文国际来源：[Disabling Local “Guest” Account](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/disabling-local-guest-account)-->

