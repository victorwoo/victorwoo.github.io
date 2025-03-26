---
layout: post
date: 2022-07-25 00:00:00
title: "PowerShell 技能连载 - 确定语言包（第 2 部分）"
description: PowerTip of the Day - Determining Language Packs (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在本系列的第二部分中，我们希望通过使用内置的 PowerShell 功能来解决我们的难题 - 获得安装的语言包。在第一部分中，我们使用了可行的控制台应用程序 (`dism.exe`)，但很复杂，需要管理员特权。

Windows 机器上的面向对象的方法通常是 WMI，您可以在其中查询描述所需信息的类，并在不做字符串转换的情况下获取信息。WMI 的困难部分是找到合适的类名。

这是我们的解决方案：

```powershell
$os = Get-CIMInstance -ClassName Win32_OperatingSystem
$os.MUILanguages
```

当您使用 `dism.exe` 将其与我们第一部分的解决方案进行比较时，您会立即发现它的速度更快，更方便。但是，两种方法最后都返回相同的信息。

<!--本文国际来源：[Determining Language Packs (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/determining-language-packs-part-2)-->

