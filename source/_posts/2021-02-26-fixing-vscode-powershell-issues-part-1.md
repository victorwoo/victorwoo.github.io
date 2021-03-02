---
layout: post
date: 2021-02-26 00:00:00
title: "PowerShell 技能连载 - 修复 VSCode PowerShell 问题（第 1 部分）"
description: PowerTip of the Day - Fixing VSCode PowerShell Issues (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有时，VSCode 在尝试启动 PowerShell 引擎时停止，或者报告诸如 "Language Server Startup failed" 之类的错误。

如果您遇到后一种异常，则可能与企业中的安全设置有关。要解决此问题，请在 PowerShell 控制台中运行以下行（这是一长行代码）：

```powershell
Import-Module $HOME\.vscode\extensions\ms-vscode.powershell*\modules\PowerShellEditorServices\PowerShellEditorServices.psd1
```

如果您没有得到提示，那么这不是造成问题的原因。如果确实收到提示要求确认导入此模块的提示，则只需允许运行“来自不受信任的发布者的软件”。该确认仅需要一次，因此下次 VSCode 尝试使用此模块启动 PowerShell 引擎时，很可能会解决您的问题。

<!--本文国际来源：[Fixing VSCode PowerShell Issues (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/fixing-vscode-powershell-issues-part-1)-->
