---
layout: post
date: 2020-02-06 00:00:00
title: "PowerShell 技能连载 - 安装并试运行 Windows Terminal"
description: PowerTip of the Day - Installing and Test-Driving Windows Terminal
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
Windows Terminal 是一个新的多选项卡的用于基于控制台的外壳程序。它可以通过 Microsoft Store 正式获得，当前需要 Windows 10 1903 或更高版本。

要从 Microsoft Store 安装它，您首先需要注册，这很令人沮丧。如果要匿名安装 Windows Terminal（并且已在上一个技巧中安装Chocolatey），只需从提升的 PowerShell 中运行以下代码：

```powershell
# download installation code
$code = Invoke-WebRequest -Uri 'https://chocolatey.org/install.ps1' -UseBasicParsing
# invoke installation code
Invoke-Expression $code

# install windows terminal
choco install microsoft-windows-terminal -y
```

一旦 Windows Terminal 安装好，您可以通过 "wt" 命令启动它。

<!--本文国际来源：[Installing and Test-Driving Windows Terminal](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/installing-and-test-driving-windows-terminal)-->

