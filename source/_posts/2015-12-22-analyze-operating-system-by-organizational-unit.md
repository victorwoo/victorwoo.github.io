layout: post
date: 2015-12-22 12:00:00
title: "PowerShell 技能连载 - 根据 OU 分析操作系统"
description: PowerTip of the Day - Analyze Operating System by Organizational Unit
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
以下是一个快捷的脚本，扫描 Active Directory 中的所有 OU，得到所有的计算机账户，然后将每个 OU 的信息按照操作系统分组：

    #requires -Version 2 -Modules ActiveDirectory
    
    Get-ADOrganizationalUnit -Filter * |
      ForEach-Object {
        $OU = $_
    
        Get-ADComputer -Filter * -SearchBase $OU.DistinguishedName -SearchScope SubTree -Properties Enabled, OperatingSystem |
          Where-Object { $_.Enabled -eq $true } |
          Group-Object -Property OperatingSystem -NoElement |
          Select-Object -Property Count, Name, OU, OUDN |
          ForEach-Object {
            $_.OU = $OU.Name
            $_.OUDN = $OU.DistinguishedName
            $_
          }
      } |
      Out-GridView

<!--more-->
本文国际来源：[Analyze Operating System by Organizational Unit](http://powershell.com/cs/blogs/tips/archive/2015/12/22/analyze-operating-system-by-organizational-unit.aspx)
