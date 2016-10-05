layout: post
date: 2015-07-13 11:00:00
title: "PowerShell 技能连载 - 简单的 AD 组管理"
description: PowerTip of the Day - Simple AD Group Management
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
假设您已下载安装了微软免费的 RSAT 工具，那么管理 AD 组合组成员会相当轻松。以下几行代码演示了如何入门：

    #requires -Version 1 -Modules ActiveDirectory
    # create new AD group
    New-ADGroup -DisplayName PowerShellGurus -GroupScope DomainLocal -Name PSGurus
    
    # get group
    Get-ADGroup -Identity PSGurus -Credential $cred -Server 172.16.14.53
    
    
    # select users by some criteria
    $newMembers = Get-ADUser -Filter 'Name -like "User*"'
    
    # add them to new AD group
    Add-ADGroupMember -Identity 'PSGurus' -Members $newMembers
    
    # list members of group
    Get-ADGroupMember -Identity PSGurus

<!--more-->
本文国际来源：[Simple AD Group Management](http://community.idera.com/powershell/powertips/b/tips/posts/simple-ad-group-management)
