---
layout: post
date: 2019-05-27 00:00:00
title: "PowerShell 技能连载 - 开发 PowerShell Core 还是 Windows PowerShell 脚本"
description: PowerTip of the Day - Marking Scripts for PowerShell Core or Windows PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您可能知道，有两种类型的 PowerShell：随着 Windows 操作系统分发的 Windows PowerShell 是基于完整的 .NET Framework；而 PowerShell 6 以及更高版本是开源、跨平台，并且基于（有限的）.NET Core 和 Standard。

如果您开发能够在两类系统上执行的脚本，那非常棒！不过如果如果知道您的代码是基于其中的一个系统，请确保在脚本的顶部添加合适的 `#requires` 语句。

这段代码只能在 PowerShell 6 及更高版本运行（假设您已事先将它保存为文件）：

```powershell
#requires -PSEdition Core
"This runs in PowerShell 6 and better only..."
```

类似地，以下代码只能在 Windows PowerShell 中运行：

```powershell
#requires -PSEdition Desktop
"This runs in Windows PowerShell only..."
```

<!--本文国际来源：[Marking Scripts for PowerShell Core or Windows PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/marking-scripts-for-powershell-core-or-windows-powershell)-->

