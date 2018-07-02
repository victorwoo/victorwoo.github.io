---
layout: post
date: 2018-06-26 00:00:00
title: "PowerShell 技能连载 - 理解脚本块日志（第 3 部分）"
description: PowerTip of the Day - Understanding Script Block Logging (Part 3)
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
这是关于 PowerShell 脚本块日志的迷你系列的第 2 部分。缺省情况下，只有被认为有潜在威胁的命令会记录日志。当启用了详细日志后，由所有用户执行的所有执行代码都会被记录。

要启用详细模式，您需要管理员特权。以下是一个启用详细日志的函数：

```powershell
function Enable-VerboseLogging
{
  <#
      .SYNOPSIS
      Enables verbose script block logging. 
      Requires Administrator privileges.

      .DESCRIPTION
      Turns script block logging on. Any code that is sent to 
      PowerShell will be logged.

      .EXAMPLE
      Enable-VerboseLogging
      Enables script block logging. 
      Administrator privileges required.
  #>


  $path = "Registry::HKLM\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
  $exists = Test-Path -Path $path
  try
  {

  $ErrorActionPreference = 'Stop'
  if (!$exists) { $null = New-Item -Path $path -Force }
  
  Set-ItemProperty -Path $path -Name EnableScriptBlockLogging -Type DWord -Value 1
  Set-ItemProperty -Path $path -Name EnableScriptBlockInvocationLogging -Type DWord -Value 1

  }
  catch
  {
    Write-Warning "Administrator privileges required. Run this command from an elevated PowerShell."
  }
}
```

当您运行 `Enable-VerboseLogging` 之后，所有 PowerShell 代码将会记录到日志中。您可以使用我们之前介绍的方式之一来读取记录的代码，例如我们的 `Get-LoggedCode`：

```powershell
function Get-LoggedCode
{
  # read all raw events
  $logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }
  Get-WinEvent -FilterHashtable $logInfo | 
  # take each raw set of data...
  ForEach-Object {
    # create a new object and extract the interesting
    # parts from the raw data to compose a "cooked"
    # object with useful data
    [PSCustomObject]@{
      # when this was logged
      Time = $_.TimeCreated
      # script code that was logged
      Code = $_.Properties[2].Value
      # if code was split into multiple log entries,
      # determine current and total part
      PartCurrent = $_.Properties[0].Value
      PartTotal = $_.Properties[1].Value
                
      # if total part is 1, code is not fragmented
      IsMultiPart = $_.Properties[1].Value -ne 1
      # path of script file (this is empty for interactive
      # commands)
      Path = $_.Properties[4].Value
      # log level
      # by default, only level "Warning" will be logged:
      Level = $_.LevelDisplayName
      # user who executed the code (SID)
      User = $_.UserId
    }
  } 
} 
```

请注意只有改变日志设置需要管理员特权。而所有用户都可以读取记录的数据。

如果您希望禁止详细模式并且返回到缺省的设置，请使用这个函数：

```powershell
function Get-LoggedCode
{
  # read all raw events
  $logInfo = @{ ProviderName="Microsoft-Windows-PowerShell"; Id = 4104 }
  Get-WinEvent -FilterHashtable $logInfo | 
  # take each raw set of data...
  ForEach-Object {
    # create a new object and extract the interesting
    # parts from the raw data to compose a "cooked"
    # object with useful data
    [PSCustomObject]@{
      # when this was logged
      Time = $_.TimeCreated
      # script code that was logged
      Code = $_.Properties[2].Value
      # if code was split into multiple log entries,
      # determine current and total part
      PartCurrent = $_.Properties[0].Value
      PartTotal = $_.Properties[1].Value
                
      # if total part is 1, code is not fragmented
      IsMultiPart = $_.Properties[1].Value -ne 1
      # path of script file (this is empty for interactive
      # commands)
      Path = $_.Properties[4].Value
      # log level
      # by default, only level "Warning" will be logged:
      Level = $_.LevelDisplayName
      # user who executed the code (SID)
      User = $_.UserId
    }
  } 
} 
```

请注意即便详细脚本日志被关闭，PowerShell 将仍会记录和安全相关的代码。

<!--more-->
本文国际来源：[Understanding Script Block Logging (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/understanding-script-block-logging-part-3)
