layout: post
date: 2017-02-26 16:00:00
title: "PowerShell 技能连载 - 显示或隐藏窗口"
description: PowerTip of the Day - Show or Hide Windows
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
PowerShell 可以调用 Windows 内部的 API，在这个例子中，我们想向您展示如何改变一个应用程序窗口的显示状态。比如可以最大化、最小化、隐藏或显示窗口。

这个例子使用 PowerShell 5 最新的枚举特性对 `showstate` 数值赋予有意义的名字。在 PowerShell 的更早版本中，只需要移除枚举部分，并在代码中直接使用合适的 `showstate` 数字即可。

这里的学习要点是如何使用 `Add-Type` 来包装一个 C# 形式的 API 方法并在 PowerShell 代码中返回一个暴露这个方法的 type：

```powershell
#requires -Version 5
# this enum works in PowerShell 5 only
# in earlier versions, simply remove the enum,
# and use the numbers for the desired window state
# directly

Enum ShowStates
{
  Hide = 0
  Normal = 1
  Minimized = 2
  Maximized = 3
  ShowNoActivateRecentPosition = 4
  Show = 5
  MinimizeActivateNext = 6
  MinimizeNoActivate = 7
  ShowNoActivate = 8
  Restore = 9
  ShowDefault = 10
  ForceMinimize = 11
}


# the C#-style signature of an API function (see also www.pinvoke.net)
$code = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'

# add signature as new type to PowerShell (for this session)
$type = Add-Type -MemberDefinition $code -Name myAPI -PassThru

# access a process
# (in this example, we are accessing the current PowerShell host
#  with its process ID being present in $pid, but you can use
#  any process ID instead)
$process = Get-Process -Id $PID

# get the process window handle
$hwnd = $process.MainWindowHandle

# apply a new window size to the handle, i.e. hide the window completely
$type::ShowWindowAsync($hwnd, [ShowStates]::Hide)

Start-Sleep -Seconds 2
# restore the window handle again
$type::ShowWindowAsync($hwnd, [ShowStates]::Show)
```

请注意这个例子将 PowerShell 窗口临时隐藏 2 秒钟。您可以对任何运行中的应用程序窗口做相同的事情。只需要用 `Get-Process` 来查找目标进程，并使用它的 "`MainWindowHandle`" 属性来发送 showstate 改变请求。

一些应用程序有多个窗口。在这种情况下，您只能针对主窗口操作，否则需要先靠其它 API 来获取子窗口的句柄集合。

<!--more-->
本文国际来源：[Show or Hide Windows](http://community.idera.com/powershell/powertips/b/tips/posts/show-or-hide-windows)
