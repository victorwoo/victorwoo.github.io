---
layout: post
date: 2022-10-03 00:00:00
title: "PowerShell 技能连载 - 更新帮助"
description: PowerTip of the Day - Update Help
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您有时使用 `Get-Help` 和本地帮助，则应该偶尔运行 `Update-Help` 以更新本地帮助文件。在 Windows PowerShell 上，这需要本地管理特权，因为帮助文件存储在受保护的 Windows 文件夹中：

```powershell
PS> Update-Help -UICulture en-us -Force
```

在 PowerShell 7 上，`Update-Help` 现在有一个附加的参数 `-Scope CurrentUser`，因此您也可以在没有管理员特权的情况下更新本地帮助。

更新本地帮助很重要，因为每当您运行它时，它都会动态地查看机器上存在的 PowerShell 模块，并仅下载关于它们的帮助。如果以后添加更多模块，则不要忘记再次运行更新——还可以下载新模块的帮助文件——前提是该模块尚未发布它们。

请注意，`Update-Module` 可能会在结束时发出红色错误消息。不用担心：通常，它仅是由几个没有帮助的模块引起的。错误消息并未表明整个更新过程有问题。

<!--本文国际来源：[Update Help](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/update-help)-->

