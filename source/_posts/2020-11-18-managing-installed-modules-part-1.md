---
layout: post
date: 2020-11-18 00:00:00
title: "PowerShell 技能连载 - 管理已安装的模块（第 1 部分）"
description: PowerTip of the Day - Managing Installed Modules (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
通过 `Install-Module` 安装新的 PowerShell 模块时，PowerShell 会记住安装位置。因此，很容易获得通过 `Install-Module` 安装的模块的列表：

```powershell
PS> Get-InstalledModule

Version Name                       Repository Description
------- ----                       ---------- -----------
2.7.1.9 ISESteroids                PSGallery  Extension for PowerShell ISE 3.0 and better
2.2.0   PoSHue                     PSGallery  Script and Control your Philips Hue Bridge, Lights, Gro...
0.14.0  platyPS                    PSGallery  Generate PowerShell External Help files from Markdown
2.4     PSOneTools                 PSGallery  commands taken from articles published at https://power...
1.0     QRCodeGenerator            PSGallery  Automatically creates QR codes as PNG images for person...
1.0     ScriptBlockLoggingAnalyzer PSGallery  Functions to manage PowerShell script block logging
1.0     UserProfile                PSGallery  This module manages user profiles on local and remote c...
```

由于新版本是并行安装的，因此可以搜索不再需要的旧版本：

```powershell
Get-InstalledModule |
Get-InstalledModule -AllVersions
```

<!--本文国际来源：[Managing Installed Modules (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/managing-installed-modules-part-1)-->

