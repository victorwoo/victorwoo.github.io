---
layout: post
date: 2017-03-16 00:00:00
title: "PowerShell 技能连载 - 查找所有含桌面的配置文件"
description: PowerTip of the Day - Finding All Profiles with Desktop
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这一行代码能够列出所有本地用户配置文件中的桌面——请确保以管理员身份运行这行代码才能查看其他人的配置文件：

```powershell
Resolve-Path -Path C:\users\*\Desktop -ErrorAction SilentlyContinue
```

如果您只想获得配置文件中包含 "Desktop" 文件夹的用户名，请用以下代码：

```powershell
Resolve-Path -Path C:\users\*\Desktop -ErrorAction SilentlyContinue |
    ForEach-Object {
        $_.Path.Split('\')[-2]
    }
```

这段代码获取路径并用反斜杠将它们分割，创建一个路径元素的数组。下标 -2 是指倒数第二个元素，即用户名。

<!--本文国际来源：[Finding All Profiles with Desktop](http://community.idera.com/powershell/powertips/b/tips/posts/finding-all-profiles-with-desktop)-->
