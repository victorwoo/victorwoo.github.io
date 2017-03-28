layout: post
date: 2017-03-13 00:00:00
title: "PowerShell 技能连载 - Exploring Type Accelerators"
description: PowerTip of the Day - Exploring Type Accelerators
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
PowerShell uses a number of so-called type accelerators that help with long .NET type names. Instead of using “System.DirectoryServices.DirectoryEntry”, for example, you can simply type “ADSI”.

When you query the property FullName of a type, you always get back the underlying full .NET type name:

     
    PS C:\> [ADSI].FullName
    System.DirectoryServices.DirectoryEntry
    
    PS C:\>
     

And this line dumps all the built-in .NET type accelerators in PowerShell:

    [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::get |
      Out-GridView
    

Aside from the explicit type accelerators, there is another rule built into PowerShell: when a type resides in the namespace “System”, then you can always omit this namespace. This is why all of these are the same:

     
    PS C:\> [int].FullName
    System.Int32
    
    PS C:\> [System.Int32].FullName
    System.Int32
    
    PS C:\> [Int32].FullName
    System.Int32

<!--more-->
本文国际来源：[Exploring Type Accelerators](http://community.idera.com/powershell/powertips/b/tips/posts/exploring-type-accelerators)
