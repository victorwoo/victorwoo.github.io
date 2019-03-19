---
layout: post
date: 2018-07-02 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 7 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 7)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是关于 PowerShell 脚本块日志的迷你系列的第 7 部分。我们现在只需要一些能清理脚本快日志记录的清理工具，您需要管理员特权。

清理日之前请注意：这将清理整个 PowerShell 日志。如果您不是这台机器的所有者，请确认删除这些信息没有问题。别人可能需要用它来做法律安全分析。

以下是一个清除日志的函数：

```powershell
function Clear-PowerShellLog
{
  <#
      .SYNOPSIS
      Ckears the entire PowerShell operational log including
      script blog logging entries.
      Administrator privileges required.

      .DESCRIPTION
      Clears the complete content of the log
      Microsoft-Windows-PowerShell/Operational.
      This includes all logged script block code.

      .EXAMPLE
      Clear-PowershellLog
      Clears the entire log Microsoft-Windows-PowerShell/Operational.
  #>
  [CmdletBinding(ConfirmImpact='High')]
  param()

  try
  {
    $ErrorActionPreference = 'Stop'
    wevtutil cl Microsoft-Windows-PowerShell/Operational
  }
  catch
  {
    Write-Warning "Administrator privileges required. Run this command from an elevated PowerShell."
```

<!--本文国际来源：[Understanding Script Block Logging (Part 7)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-7)-->
