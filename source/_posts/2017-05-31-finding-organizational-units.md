layout: post
date: 2017-05-31 00:00:00
title: "PowerShell 技能连载 - 查找 OU"
description: PowerTip of the Day - Finding Organizational Units
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
（来自 Microsoft 免费的 RSAT 工具的）`Get-OrganizationalUnit` 可以基于识别名或 GUID 来搜索 OU，或者可以使用 `-Filter` 参数。

不幸的是，`-Filter` 不能方便地自动化。以下代码并不能工作，并不能返回所有名字中包含 "Test" 的 OU：

```powershell
$Name = 'Test'
Get-ADOrganizationalUnit -Filter { Name -like "*$Name*" }
```

这个结果很令人惊讶，因为以下这行代码可以工作（前提是您确实有名字包含 "Test" 的 OU）：

```powershell
Get-ADOrganizationalUnit -Filter { Name -like "*Test*" }
```

通常情况下，如果您想用简单的通配符来搜索，那么使用简单的 LDAP 过滤器十分管用。以下代码查找所有名字中包含 "Test" 的 OU：

```powershell
$Name = 'Test'
Get-ADOrganizationalUnit -LDAPFilter "(Name=*$Name*)"
```

<!--more-->
本文国际来源：[Finding Organizational Units](http://community.idera.com/powershell/powertips/b/tips/posts/finding-organizational-units)
