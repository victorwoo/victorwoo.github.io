---
layout: post
date: 2022-07-27 00:00:00
title: "PowerShell 技能连载 - 确定语言包（第 3 部分）"
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
在本系列的第二部分中，您已经看到了使用 WMI 与使用命令行工具（如 `dism.exe`）相比，使用 WMI 查询安装的操作系统语言列表要容易且快速得多。但是，WMI 仍然需要您知道适当的 WMI 类名称。

这就是为什么 PowerShell 全能的 `Get-ComputerInfo` 的原因。它为您查询各种与计算机相关的信息，然后由您决定需要哪个信息。我们也可以通过这种方法解决这个问题：

```powershell
$a = Get-ComputerInfo
$a.OsMuiLanguages
```

不好的方面是，`Get-ComputerInfo` 总是查询完整的信息集，这使得执行起来很慢。不过总比没有好，甚至比 `dism.exe` 更好，但是第二部分的直接 WMI 查询仍然是最高效的方法。

<!--本文国际来源：[Determining Language Packs (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/determining-language-packs-part-3)-->

