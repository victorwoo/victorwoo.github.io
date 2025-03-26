---
layout: post
date: 2022-11-29 07:21:07
title: "PowerShell 技能连载 - Determining Language Packs (Part 3)"
description: PowerTip of the Day - Determining Language Packs (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在本系列的第 2 部分中，您已经看到了使用 WMI 与使用命令行工具（如 `dism.exe`）相比，使用 WMI 查询安装的操作系统语言列表的速度要容易得多，且更快。但是，使用 WMI 仍然需要您知道适当的 WMI 类名。

这就是为什么 PowerShell 提供一个全能的 cmdlet `Get-ComputerInfo` 的原因。它为您查询各种与计算机相关的信息，然后将其与您联系。 我们也可以通过这种方法解决这个问题：

```powershell
$a = Get-ComputerInfo
$a.OsMuiLanguages
```

但不幸的是，`Get-ComputerInfo` 总是查询完整的信息集，这使得它很缓慢。但总比没有好，甚至比 `dism.exe` 更好，而第 2 部分的直接 WMI 查询仍然是效率最高的方法。

<!--本文国际来源：[Determining Language Packs (Part 3)](https://blog.idera.com/database-tools/determining-language-packs-part-3)-->

