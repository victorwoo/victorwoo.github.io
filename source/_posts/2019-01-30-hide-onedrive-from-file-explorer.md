---
layout: post
date: 2019-01-30 00:00:00
title: "PowerShell 技能连载 - 在文件管理器中隐藏 OneDrive"
description: PowerTip of the Day - Hide OneDrive from File Explorer
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
是否厌倦了 OneDrive 图表污染了您的文件管理器树形视图？如果您不使用 OneDrive，那么有两个很好用的函数可以在文件管理器里隐藏或显示 OneDrive 图标：

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

<!--本文国际来源：[Hide OneDrive from File Explorer](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/hide-onedrive-from-file-explorer)-->
