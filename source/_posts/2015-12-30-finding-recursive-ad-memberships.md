layout: post
date: 2015-12-30 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Finding Recursive AD Memberships
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
In AD, there is a strange-looking filter: 1.2.840.113556.1.4.1941. It is called "matching rule in chain" and can be used to quickly find nested memberships.

All you need is the DN of a member. Then, you can use it like this:

    #requires -Version 1 -Modules ActiveDirectory 
    
    $DN = 'place DN here!'
    Get-ADGroup -LDAPFilter "(member:1.2.840.113556.1.4.1941:=$($DN))"
    

Since this is a native LDAP filter, you can even use it without the ActiveDirectory module, resorting to native .NET methods:

    $DN = 'place DN here!'
    $strFilter = "(member:1.2.840.113556.1.4.1941:=$DN)"
    $objDomain = New-Object System.DirectoryServices.DirectoryEntry('LDAP://rootDSE')
    $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    $objSearcher.SearchRoot = "LDAP://$($objDomain.rootDomainNamingContext)"
    $objSearcher.PageSize = 1000
    $objSearcher.Filter = $strFilter
    $objSearcher.SearchScope = 'Subtree'
    $colProplist = 'name'
    foreach ($i in $colPropList){
      $null = $objSearcher.PropertiesToLoad.Add($i)
    }
    $colResults = $objSearcher.FindAll()
    foreach ($objResult in $colResults)
    {
      $objItem = $objResult.Properties
      $objItem.name
    }

<!--more-->
本文国际来源：[Finding Recursive AD Memberships](http://powershell.com/cs/blogs/tips/archive/2015/12/30/finding-recursive-ad-memberships.aspx)
