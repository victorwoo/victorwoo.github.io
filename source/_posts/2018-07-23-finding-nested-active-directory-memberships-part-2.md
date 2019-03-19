---
layout: post
date: 2018-07-23 00:00:00
title: "PowerShell 技能连载 - 查找嵌套的 Active Directory 成员（第 2 部分）"
description: PowerTip of the Day - Finding Nested Active Directory Memberships (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何使用 ActiveDirectory 模块中的 cmdlet 来查找某个 Active Directory 用户所有直接和间接的成员。

如果您没有权限操作 ActiveDirectory 模块，PowerShell 也可以使用纯 .NET 方法来获取成员：

```powershell
function Get-NestedGroupMember
{
  param
  (
    [Parameter(Mandatory,ValueFromPipeline)]
    [string]
    $distinguishedName
  )

  process
  {

    $DomainController = $env:logonserver.Replace("\\","")
    $Domain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DomainController")
    $Searcher = New-Object System.DirectoryServices.DirectorySearcher($Domain)
    $Searcher.PageSize = 1000
    $Searcher.SearchScope = "subtree"
    $Searcher.Filter = "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=$distinguishedName))"
    # attention: property names are case-sensitive!
    $colProplist = "name","distinguishedName"
    foreach ($i in $colPropList){$Searcher.PropertiesToLoad.Add($i) | Out-Null}
    $all = $Searcher.FindAll()

    $all.Properties | ForEach-Object {
      [PSCustomObject]@{
        # attention: property names on right side are case-sensitive!
        Name = $_.name[0]
        DN = $_.distinguishedname[0]
    } }
  }
}

# make sure you specify a valid distinguishedname for a user below
Get-NestedGroupMember -distinguishedName 'CN=UserName,DC=powershell,DC=local'
```

<!--本文国际来源：[Finding Nested Active Directory Memberships (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-nested-active-directory-memberships-part-2)-->
