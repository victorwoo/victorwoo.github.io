layout: post
title: "PowerShell 技能连载 - 简单地读取注册表值"
date: 2014-07-10 00:00:00
description: PowerTip of the Day - Reading Registry Values Easily
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
以下是最简单的读取注册表值的方法：

    $Key = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $Name = 'RegisteredOwner'
    
    $result = (Get-ItemProperty -Path "Registry::$Key" -ErrorAction Stop).$Name
    
    "Registered Windows Owner: $result"
    
只需要将 `$Key` 替换成注册表项，将 `$Name` 替换成注册表键，就能读取它的值。

<!--more-->
本文国际来源：[Reading Registry Values Easily](http://powershell.com/cs/blogs/tips/archive/2014/07/10/reading-registry-values-easily.aspx)
