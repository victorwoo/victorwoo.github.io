---
layout: post
date: 2017-02-20 00:00:00
title: "PowerShell 技能连载 - 接触 PowerShell 6.0"
description: PowerTip of the Day - Playing with PowerShell 6.0
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
PowerShell 现在是开源的，而且 PowerShell 下一个主要的 release 是在开放的环境中开发。如果您希望看一眼预览版，只需要打开源项目的发布发布页面，并且下载合适的 release：

[https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases)

而且现在 PowerShell 6.0 是跨平台的。您可以同时找到适合 Linux 或 OS X 和 Windows 操作系统的版本。

当您下载某个了 Windows 平台的 ZIP 格式的 release，请先对文件解锁（右键单击文件，选择“属性”，然后解锁）。下一步，解压压缩包。在压缩包里，找到 powershell.exe，可以双击它启动一个新的 PowerShell 6.0 控制台。它是一个完全独立发行的 PowerShell，可以和现有的 PowerShell 版本同时运行。

```powershell
PowerShell
Copyright (C) 2016 Microsoft Corporation. All rights reserved.

PS C:\Users\tobwe\Downloads\PowerShell_6.0.0-alpha.15-win10-win2k16-x64> $PSVersionTable

Name                           Value
----                           -----
PSVersion                      6.0.0-alpha
CLRVersion
WSManStackVersion              3.0
SerializationVersion           1.1.0.1
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
PSRemotingProtocolVersion      2.3
GitCommitId                    v6.0.0-alpha.15
BuildVersion                   3.0.0.0
PSEdition                      Core


PS C:\Users\tobwe\Downloads\PowerShell_6.0.0-alpha.15-win10-win2k16-x64>
```

如果您是一个开发者，请查看 GitHub 工程：您可以查看所有源代码，甚至可以加入这个版本的开发者社区。

<!--more-->
本文国际来源：[Playing with PowerShell 6.0](http://community.idera.com/powershell/powertips/b/tips/posts/playing-with-powershell-6-0)
