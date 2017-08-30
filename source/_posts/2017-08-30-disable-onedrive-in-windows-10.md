---
layout: post
date: 2017-08-30 00:00:00
title: "PowerShell 技能连载 - 禁止 Windows 10 中的 OneDrive"
description: PowerTip of the Day - Disable OneDrive in Windows 10
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
您是否也为任务栏中的 OneDrive 图标感到烦恼？如果您从未使用 OneDrive，以下是两个易于使用的 PowerShell 函数，能够帮助您在资源管理器中隐藏（和显示）OneDrive 图标：

```powershell
function Disable-OneDrive
{
    $regkey1 = 'Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    $regkey2 = 'Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    Set-ItemProperty -Path $regkey1, $regkey2 -Name System.IsPinnedToNameSpaceTree -Value 0
}


function Enable-OneDrive
{
    $regkey1 = 'Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    $regkey2 = 'Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'    
    Set-ItemProperty -Path $regkey1, $regkey2 -Name System.IsPinnedToNameSpaceTree -Value 1
}
```

执行后不需要重启，结果立即生效。

<!--more-->
本文国际来源：[Disable OneDrive in Windows 10](http://community.idera.com/powershell/powertips/b/tips/posts/disable-onedrive-in-windows-10)
