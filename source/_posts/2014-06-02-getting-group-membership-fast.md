---
layout: post
title: "PowerShell 技能连载 - 快速获取成员身份"
date: 2014-06-02 00:00:00
description: PowerTip of the Day - Getting Group Membership - Fast
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您需要了解您的用户账户所在的 Active Directory 组，通常需要查询 Active Directory，并且还需要查找嵌套的组成员身份。

以下是一种快速获取您所在的组（包括嵌套的以及本地组）成员身份的方法。这段脚本查看您的存取令牌（它管理了您的各种权限）然后从您的令牌中读取所有 SID 并将 SID 转换为真实名称。

请注意您只能对当前用户使用这种技术。它很适合用作登录脚本，用来做一些基于组成员身份的操作。

    [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value |
      ForEach-Object {
        $sid = $_
        $objSID = New-Object System.Security.Principal.SecurityIdentifier($sid) 
        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount]) 
        $objUser.Value
      } 

<!--本文国际来源：[Getting Group Membership - Fast](http://community.idera.com/powershell/powertips/b/tips/posts/getting-group-membership-fast)-->
