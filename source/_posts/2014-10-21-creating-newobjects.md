layout: post
date: 2014-10-21 11:00:00
title: "PowerShell 技能连载 - 创建新对象"
description: PowerTip of the Day - Creating New Objects
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
_适用于 PowerShell 3.0 或以上版本_

这是一个创建自定义对象的简单有效的方法：

    $object = [PSCustomObject]@{
      Name = 'Weltner'
      ID = 123
      Active = $true
    } 
    

这将创建一个包含预设属性值的完整功能的 PowerShell 对象：

    PS> $object 
    
    Name                                                ID                    Active
    ----                                                --                    ------
    Weltner                                            123                     True
    
    
    
    PS> $object.Name
    Weltner
    
    PS> $object.Active
    True
    
    PS>

<!--more-->
本文国际来源：[Creating New Objects](http://community.idera.com/powershell/powertips/b/tips/posts/creating-newobjects)
