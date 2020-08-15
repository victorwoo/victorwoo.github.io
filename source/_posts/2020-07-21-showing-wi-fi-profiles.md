---
layout: post
date: 2020-07-21 00:00:00
title: "PowerShell 技能连载 - 显示 Wi-Fi 配置"
description: PowerTip of the Day - Showing Wi-Fi Profiles
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 不仅限于执行 cmdlet，还可以运行可执行文件。例如，没有内置的 cmdlet 可以列出现有的 Wi-Fi 配置文件，但是 `netsh.exe` 可以提供以下信息：

```powershell
PS> netsh wlan show profiles
```

使用 `Select-String` 仅识别与模式匹配的输出行（冒号后面跟着文本），然后使用 `-split` 运算符在以 ": " 分隔字符串，并返回最后一个数组元素 (index -1) 得到配置文件名称：

```powershell
PS> netsh wlan show profiles |
        Select-String ":(.{1,})$" |
        ForEach-Object { ($_.Line -split ': ')[-1] }
```

<!--本文国际来源：[Showing Wi-Fi Profiles](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/showing-wi-fi-profiles)-->

