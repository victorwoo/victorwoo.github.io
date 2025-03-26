---
layout: post
date: 2022-07-07 00:00:00
title: "PowerShell 技能连载 - 下载文件"
description: PowerTip of the Day - Downloading Files
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
可以通过许多方法实现简单的文件下载。例如，使用 `Invoke-RestMethod`、`Invoke-WebRequest` 或通过 `BitsTransfer` 模块。

如果您需要下载流式内容，那么需要更复杂的命令。在 Windows 机器上，您可以下载并安装 `PSODownloader` 模块：


```powershell
Install-Module -Name PSODownloader -Scope CurrentUser
```

它为您提供了一个更简单的 cmdlet：`Invoke-DownloadFile`。您可以先将要下载的 URL 复制到剪贴板然后调用该命令，或者使用 `-Url` 参数。

在此可以查看更多信息：

[https://github.com/TobiasPSP/Modules.PsoDownloader](https://github.com/TobiasPSP/Modules.PsoDownloader)

<!--本文国际来源：[Downloading Files](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/downloading-files-2)-->

