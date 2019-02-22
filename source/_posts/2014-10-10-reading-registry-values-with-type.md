---
layout: post
date: 2014-10-10 11:00:00
title: "PowerShell 技能连载 - 获取包含数据类型信息在内的注册表键值"
description: PowerTip of the Day - Reading Registry Values with Type
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
_适用于 PowerShell 所有版本_

读取所有注册表信息时，如果您不需要数据类型信息，那么十分简单：只需要用 `Get-ItemProperty` 即可：

    Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run

如果您确实需要数据类新信息，那么需要做点额外的事情：

    $key = Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
    
    $key.GetValueNames() |
      ForEach-Object {
        $ValueName = $_
    
        $rv = 1 | Select-Object -Property Name, Type, Value
        $rv.Name = $ValueName
        $rv.Type = $key.GetValueKind($ValueName)
        $rv.Value = $key.GetValue($ValueName)
        $rv 
      }

<!--本文国际来源：[Reading Registry Values with Type](http://community.idera.com/powershell/powertips/b/tips/posts/reading-registry-values-with-type)-->
