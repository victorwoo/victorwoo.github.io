---
layout: post
date: 2018-06-27 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 4 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
这是关于 PowerShell 脚本块日志的迷你系列的第 4 部分。到目前为止，您已经了解了如何读取记录的 PowerShell 代码，以及如何打开详细模式。打开详细模式后，机器上运行的所有 PowerShell 代码都会记录下来，所以会产生大量的数据。为了不覆盖旧的日志数据，您需要增加日志文件的尺寸。以下是操作方法：

```powershell
function Set-SBLLogSize
{
  <#
      .SYNOPSIS
      Sets a new size for the script block logging log. 
      Administrator privileges required.

      .DESCRIPTION
      By default, the script block log has a maximum size of 15MB 
      which may be too small to capture and log PowerShell activity 
      over a given period of time. With this command, 
      you can assign more memory to the log.

      .PARAMETER MaxSizeMB
      New log size in Megabyte

      .EXAMPLE
      Set-SBLLogSize -MaxSizeMB 100
      Sets the maximum log size to 100MB. 
      Administrator privileges required.
  #>


  param
  (
    [Parameter(Mandatory)]
    [ValidateRange(15,3000)]
    [int]
    $MaxSizeMB
  )
  
  $Path = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-PowerShell/Operational"
  try
  {
    $ErrorActionPreference = 'Stop'
    Set-ItemProperty -Path $Path -Name MaxSize -Value ($MaxSizeMB * 1MB)  
  }
  catch
  {
    Write-Warning "Administrator privileges required. Run this command from an elevated PowerShell."
  }
}
```

要将日志文件的尺寸从缺省的 15MB 增加到 100MB，请运行以下代码（需要管理员特权）：

```powershell
PS> Set-SBLLogSize -MaxSizeMB 100
```

<!--本文国际来源：[Understanding Script Block Logging (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-4)-->
