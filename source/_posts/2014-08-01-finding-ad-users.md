layout: post
date: 2014-08-01 11:00:00
title: "PowerShell 技能连载 - 查找 AD 用户"
description: PowerTip of the Day - Finding AD Users
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
_适用于所有 PowerShell 版本_

假如您已登录到了一个活动目录域中，那么只需要执行一些简单的命令就可以搜索活动目录。在前一个技巧中我们演示了最基本的脚本。以下是一个扩展，它能够定义一个搜索的根（搜索的起点），就像一个扁平的搜索一样（相对于在容器中递归而言）。

它也演示了如何将活动目录的搜索结果转换成实际的用户对象：

    $SAMAccountName = 'tobias'
    $SearchRoot = 'LDAP://OU=customer,DC=company,DC=com'
    $SearchScope = 'OneLevel'
    
    $ldap = "(&(objectClass=user)(samAccountName=*$SAMAccountName*))"
    $searcher = [adsisearcher]$ldap
    $searcher.SearchRoot = $SearchRoot
    $searcher.PageSize = 999
    $searcher.SearchScope = $SearchScope
    
    $searcher.FindAll() | 
      ForEach-Object { $_.GetDirectoryEntry()  } | 
      Select-Object -Property *

<!--more-->
本文国际来源：[Finding AD Users](http://community.idera.com/powershell/powertips/b/tips/posts/finding-ad-users)
