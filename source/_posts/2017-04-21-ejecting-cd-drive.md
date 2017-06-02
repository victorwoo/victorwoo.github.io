---
layout: post
date: 2017-04-21 00:00:00
title: "PowerShell 技能连载 - 弹出 CD 驱动器"
description: PowerTip of the Day - Ejecting CD Drive
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
以下是一个用 WMI 弹出 CD 驱动器的小函数。它首先向 WMI 请求所有的 CD 驱动器，然后使用 explorer 对象模型导航到该驱动器并调用它的 "Eject" 上下文菜单项。

```powershell
function Eject-CD
{
  $drives = Get-WmiObject Win32_Volume -Filter "DriveType=5"
  if ($drives -eq $null)
  {
    Write-Warning "Your computer has no CD drives to eject."
    return
  }
  $drives | ForEach-Object {
    (New-Object -ComObject Shell.Application).Namespace(17).ParseName($_.Name).InvokeVerb("Eject")
  }
}

Eject-CD
```

<!--more-->
本文国际来源：[Ejecting CD Drive](http://community.idera.com/powershell/powertips/b/tips/posts/ejecting-cd-drive)
