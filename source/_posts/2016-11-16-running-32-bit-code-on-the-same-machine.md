layout: post
date: 2016-11-16 00:00:00
title: "PowerShell 技能连载 - 在同一台机器上运行 32 位代码"
description: PowerTip of the Day - Running 32-bit Code on the Same Machine
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
如果您需要在 64 位脚本中运行 32 位 PowerShell 代码，假设您是管理员，并且使用远程操作功能，您可以远程操作您的系统：

```powershell
$code = {
  [IntPtr]::Size
  Get-Process
}


Invoke-Command -ScriptBlock $code -ConfigurationName microsoft.powershell32 -ComputerName $env:COMPUTERNAME
```

这将在 32 位环境中运行 `$code` 中的脚本块。该指针返回的 size 是 4，这是 32 位的证据。当您直接运行脚本块，返回的是 8 字节（64 比特）。

<!--more-->
本文国际来源：[Running 32-bit Code on the Same Machine](http://community.idera.com/powershell/powertips/b/tips/posts/running-32-bit-code-on-the-same-machine)
