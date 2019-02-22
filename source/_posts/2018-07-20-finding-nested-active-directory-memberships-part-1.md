---
layout: post
date: 2018-07-20 00:00:00
title: "PowerShell 技能连载 - 查找嵌套的 Active Directory 成员（第 1 部分）"
description: PowerTip of the Day - Finding Nested Active Directory Memberships (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`ActiveDirectory` 模块（免费的 RSAT 工具的一部分）提供许多 AD cmdlet。其中一个可以读取整个直接组的成员，例如：

```powershell
PS> Get-ADPrincipalGroupMembership  -Identity $env:username
```

然而，这个 cmdlet 无法列出间接组的成员，而且它还有一个 bug：在某些场景下，它只是报告“未知错误”。

这是一个简单的读取所有组成员（包括间接成员）的替代方案：

```powershell
function Get-NestedGroupMember
{
param
(
[Parameter(Mandatory,ValueFromPipeline)]
[string]
$Identity
)

process
{
$user = Get-ADUser -Identity $Identity
$userdn = $user.DistinguishedName
$strFilter = "(member:1.2.840.113556.1.4.1941:=$userdn)"
Get-ADGroup -LDAPFilter $strFilter -ResultPageSize 1000
}
}


Get-NestedGroupMember -Identity $env:username |
Select-Object -Property Name, DistinguishedName
```

<!--本文国际来源：[Finding Nested Active Directory Memberships (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-nested-active-directory-memberships-part-1)-->
