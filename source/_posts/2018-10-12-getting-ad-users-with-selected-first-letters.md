---
layout: post
date: 2018-10-12 00:00:00
title: "PowerShell 技能连载 - Getting AD Users with Selected First Letters"
description: PowerTip of the Day - Getting AD Users with Selected First Letters
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
How would you query for all AD users with names that start with a “e”-“g”? You shouldn’t use a client-side filter such as Where-Object. One thing you can do is use the -Filter parameter with logical operators such as -and and -or:

    Get-ADUser -filter {(name -lt 'E') -or (name -gt 'G')} |
      Select-Object -ExpandProperty Name
    

this example requires the free RSAT tools from Microsoft to be installed)

<!--more-->
本文国际来源：[Getting AD Users with Selected First Letters](http://community.idera.com/powershell/powertips/b/tips/posts/getting-ad-users-with-selected-first-letters)
