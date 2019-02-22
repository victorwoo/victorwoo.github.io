---
layout: post
date: 2018-02-05 00:00:00
title: "PowerShell 技能连载 - 查找嵌套的 AD 组成员"
description: PowerTip of the Day - Finding Nested AD Group Memberships
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下代码查找某个 Active Directory 用户属于哪些组（包括嵌套的组成员）。该代码需要 ActiveDirectory 模块。

```powershell
#requires -Module ActiveDirectory
    
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
```

要查找组成员，只需要执行 `Get-NestedGroupMember`，跟上用户名即可。该函数和 `Get-ADUser` 接受同样的身份信息，所以您可以传入 SamAccountName、SID、GUID，或 distinguishedName。

<!--本文国际来源：[Finding Nested AD Group Memberships](http://community.idera.com/powershell/powertips/b/tips/posts/finding-nested-ad-group-memberships)-->
