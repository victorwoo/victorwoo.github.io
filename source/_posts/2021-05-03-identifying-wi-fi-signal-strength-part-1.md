---
layout: post
date: 2021-05-03 00:00:00
title: "PowerShell 技能连载 - 检测 Wi-Fi 信号强度（第 1 部分）"
description: PowerTip of the Day - Identifying Wi-Fi Signal Strength (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您已连接到无线网络，则以下这行代码可提供当前信号强度：

```powershell
    PS> @(netsh wlan show interfaces) -match '^\s+Signal' -replace '^\s+Signal\s+:\s+',''
    80%
```

信号强度来自 `netsh.exe` 提供的文本输出。将其包含在 `@()` 中可确保它始终返回一个数组。然后，`-match` 运算符使用正则表达式来标识在行首包含单词 "Signal" 的行。后面的 `-replace` 运算符使用正则表达式删除信号强度之前的文本。

如果您不喜欢正则表达式，则可以使用其他方法来实现，例如：

```powershell
    PS> (@(netsh wlan show interfaces).Trim() -like 'Signal*').Split(':')[-1].Trim()
    80%
```

这段代码中，将首先修剪 `netsh.exe` 返回的每一行（删除两端的空白）。接下来，经典的 `-like` 运算符选择以 "Signal" 开头的行。然后用 ":" 分隔该行，并使用最后一部分（索引为 -1）。再次清除信号强度两端的空白。

如果两个命令均未返回任何内容，请检查您的计算机是否已连接到无线网络。您可能还希望仅使用 `netsh.exe` 命令的参数来运行它，而没有任何文本运算符来查看命令的原始输出。

<!--本文国际来源：[Identifying Wi-Fi Signal Strength (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/identifying-wi-fi-signal-strength-part-1)-->

