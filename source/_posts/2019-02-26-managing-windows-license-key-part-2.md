---
layout: post
date: 2019-02-26 00:00:00
title: "PowerShell 技能连载 - 管理 Windows 授权密钥（第 2 部分）"
description: PowerTip of the Day - Managing Windows License Key (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
大多数的授权密钥管理任务都可以通过 `slmgr` 命令完成。

This command is actually an ancient VBScript. To read all of your license settings, for example, try this:
这个命令实际上是一个古老的 VBScript。例如要读取所有许可证设置，请使用以下代码：

```powershell
PS> slmgr.vbs /dlv
```

这将打开一个独立的窗口，并且显示许多许可证激活细节。在对话框窗口中显示信息对于 PowerShell 和自动化操作帮助不大，而且通过 `cscript.exe` 运行该 VBScript，可能会失败：

```powershell
PS> slmgr.vbs /dlv

PS> cscript.exe slmgr.vbs /dlv
Microsoft (R) Windows Script Host, Version 5.812
Copyright (C) Microsoft Corporation. All Rights Reserved.

Script file "C:\Users\tobwe\slmgr.vbs" not found.

PS>
```

您可以将缺省的 VBS 宿主改为 `cscript.exe`，但是一个更好的不改变全局设置的做法是：找出这个 VBScript 的完整路径，然后用绝对路径执行它。以下是获得 VBScript 路径的办法：

```powershell
PS> Get-Command slmgr.vbs | Select-Object -ExpandProperty Source
C:\WINDOWS\system32\slmgr.vbs
```

这段代码将读取该信息输出到 PowerShell 控制台：

```powershell
$Path = Get-Command slmgr.vbs | Select-Object -ExpandProperty Source
$Data = cscript.exe //Nologo $Path /dlv
$Data
```

不过，`$Data` 包含了难以阅读的纯文本，而且是本地化的。用这种方法获取许可证和激活信息不太优雅。

由于 `slmgr.exe` 可以做许多神奇的许可证任务，就如打开它的帮助时看到的那样，让我们在随后的技能中检查它的源码，并且跳过以前的 VBScript 直接获取信息。

```powershell
PS> slmgr /?
```

今日知识点：

* Windows 许可证管理通常是通过一个 VBScript `slmgr.vbs` 来实现。当您通过 "`/?`" 调用它，将会获得该命令参数的帮助信息。
* PowerShell 可以调用 `slmgr`。要接收执行结果，请通过 cscript.exe 调用它，并且向 `slmgr.vbs` 提供完整的（绝对）路径。
* `Get-Command` 是一个查找系统文件夹（在 `$env:PATH` 中列出的）中的文件的完整（绝对）路径的方法。

<!--本文国际来源：[Managing Windows License Key (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-windows-license-key-part-2)-->
