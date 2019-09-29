---
layout: post
date: 2019-09-23 00:00:00
title: "PowerShell 技能连载 - 安装 PowerShell Core"
description: PowerTip of the Day - Installing PowerShell Core
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您也许知道，Windows PowerShell（随 Windows 分发的）已成为过去，所有的工作都投入到新的跨平台 PowerShell Core 的开发中。新版的 PowerShell 还没有在 Windows 中提供开箱即用的功能，所以如果要使用它，您需要手动下载。

幸运的是，有一个脚本可以为您完成繁重的工作。这是用来下载该脚本的代码：

```powershell
Invoke-RestMethod https://aka.ms/install-powershell.ps1
```

如果您希望将该脚本保存到一个文件，请使用以下代码：

```powershell
$Path = "$home\desktop\installps.ps1"

Invoke-RestMethod https://aka.ms/install-powershell.ps1 | Set-Content -Path $Path -Encoding UTF8
notepad $Path
```

这将下载该脚本并在一个记事本中打开该脚本。该脚本文件存放在桌面上，这样您可以用鼠标右键单击它并使用 PowerShell 执行它来下载并安装最新生产版的 PowerShell Core。

<!--本文国际来源：[Installing PowerShell Core](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-powershell-core)-->

