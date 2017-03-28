layout: post
date: 2017-02-28 00:00:00
title: "PowerShell 技能连载 - Power Shell 5 的类继承（第一部分）"
description: PowerTip of the Day - Inheriting Classes in PowerShell 5 (part 1)
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
PowerShell 5 内置了类的支持。您可以使用这个新特性来增强已有的 .NET 类的功能。以下是一个例子：创建一个包含新功能的增强的进程类。

进程通常是由 `System.Diagnostics.Process` 对象代表。它们只有有限的功能，并且假设没有能直接使用的以友好方式关闭一个应用程序的方法。您可以杀除进程（会丢失未保存的数据），或关闭它（用户可以取消关闭）。

以下是一个新的 继承于 `System.Diagnostics.Process` 的名为 `AppInstance` 的类。所以它拥有 `Process` 类中所有已有的功能，您可以增加额外的属性和方法：

```powershell
#requires -Version 5
class AppInstance : System.Diagnostics.Process
{
  # Constructor, being called when you instantiate a new object of
  # this class
  AppInstance([string]$Name) : base()
  {
    # launch the process, get a regular process object, and then
    # enhance it with additional functionality
    $this.StartInfo.FileName = $Name
    $this.Start()
    $this.WaitForInputIdle()
  }

  # for example, rename an existing method
  [void]Stop()
  {
    $this.Kill()
  }

  # or invent new functionality
  # Close() closes the window gracefully. Unlike Kill(),
  # the user gets the chance to save unsaved work for
  # a specified number of seconds before the process
  # is killed
  [void]Close([Int]$Timeout = 0)
  {
    # send close message
    $this.CloseMainWindow()
    # wait for success
    if ($Timeout -gt 0)
    {
      $null = $this.WaitForExit($Timeout * 1000)
    }
    # if process still runs (user aborted request), kill forcefully
    if ($this.HasExited -eq $false)
    {
      $this.Stop()
    }
  }

  # example of how to change a property like process priority
  [void]SetPriority([System.Diagnostics.ProcessPriorityClass] $Priority)
  {
    $this.PriorityClass = $Priority
  }

  [System.Diagnostics.ProcessPriorityClass]GetPriority()
  {
    if ($this.HasExited -eq $false)
    {
      return $this.PriorityClass
    }
    else
    {
      Throw "Process PID $($this.Id) does not run anymore."
    }
  }

  # add static methods, for example a way to list all processes
  # variant A: no arguments
  static [System.Diagnostics.Process[]] GetAllProcesses()
  {
    return [AppInstance]::GetAllProcesses($false)
  }
  # variant B: submit $false to see only processes that have a window
  static [System.Diagnostics.Process[]] GetAllProcesses([bool]$All)
  {
    if ($All)
    {
      return Get-Process
    }
    else
    {
      return Get-Process | Where-Object { $_.MainWindowHandle -ne 0 }
    }
  }
}

# you can always run static methods
[AppInstance]::GetAllProcesses($true) | Out-GridView -Title 'All Processes'
[AppInstance]::GetAllProcesses($false) | Out-GridView -Title 'Processes with Window'


# this is how you instantiate a new process and get back
# a new enhanced process object
# classic way:
# $notepad = New-Object -TypeName AppInstance('notepad')
# new (and faster) way in PowerShell 5 to instantiate new objects:
$notepad = [AppInstance]::new('notepad')

# set a different process priority
$notepad.SetPriority('BelowNormal')

# add some text to the editor to see the close message
Start-Sleep -Seconds 5

# close the application and offer to save changes for a maximum
# of 10 seconds
$notepad.Close(10)
```

如您在这个例子中所见，当您从这个类创建一个新实例时，它启动了一个新的进程，而且这些进程照常暴露出相同的属性和方法。而且，有一些新的例如 `SetPriority()` 和 `Close()` 的新方法。

<!--more-->
本文国际来源：[Inheriting Classes in PowerShell 5 (part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/inheriting-classes-in-powershell-5-part-1)
