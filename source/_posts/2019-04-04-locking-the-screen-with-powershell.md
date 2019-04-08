---
layout: post
date: 2019-04-04 00:00:00
title: "PowerShell 技能连载 - 用 PowerShell 锁定屏幕"
description: PowerTip of the Day - Locking the Screen with PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
以下是一个名为 `Lock-Screen` 的 PowerShell 函数，它可以锁定屏幕，禁止用户操作。可以指定一个自定义消息，并且可以在锁定时将屏幕调暗。

以下是一个调用示例：

```powershell
PS> Lock-Screen -LockSeconds 4 -DimScreen -Title 'Go away and come back in {0} seconds.'
```

以下是 `Lock-Screen` 的源码：

```powershell
Function Lock-Screen
{
  [CmdletBinding()]
  param
  (
    # number of seconds to lock
    [int]
    $LockSeconds = 10,

    # message shown. Use {0} to insert remaining seconds
    # do not use {0} for a static message
    [string]
    $Title = 'wait for {0} more seconds...',

    # dim screen
    [Switch]
    $DimScreen
  )

  # when run without administrator privileges, the keyboard will not be blocked!

  # get access to API functions that block user input
  # blocking of keyboard input requires admin privileges
  $code = @'
    [DllImport("user32.dll")]
    public static extern int ShowCursor(bool bShow);

    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
'@

  $userInput = Add-Type -MemberDefinition $code -Name Blocker -Namespace UserInput -PassThru

  # get access to UI functionality
  Add-Type -AssemblyName PresentationFramework
  Add-Type -AssemblyName PresentationCore

  # set window opacity
  $opacity = 1
  if ($DimScreen) { $opacity = 200 }

  # create a message label
  $label = New-Object -TypeName Windows.Controls.Label
  $label.FontSize = 60
  $label.FontFamily = 'Consolas'
  $label.FontWeight = 'Bold'
  $label.Background = 'Transparent'
  $label.Foreground = 'Blue'
  $label.VerticalAlignment = 'Center'
  $label.HorizontalAlignment = 'Center'


  # create a window
  $window = New-Object -TypeName Windows.Window
  $window.WindowStyle = 'None'
  $window.AllowsTransparency = $true
  $color = [Windows.Media.Color]::FromArgb($opacity, 0,0,0)
  $window.Background = [Windows.Media.SolidColorBrush]::new($color)
  $window.Opacity = 0.8
  $window.Left = $window.Top = 0
  $window.WindowState = 'Maximized'
  $window.Topmost = $true
  $window.Content = $label

  # block user input
  $null = $userInput::BlockInput($true)
  $null = $userInput::ShowCursor($false)

  # show window and display message
  $null = $window.Dispatcher.Invoke{
    $window.Show()
    $LockSeconds..1 | ForEach-Object {
      $label.Content = ($title -f $_)
      $label.Dispatcher.Invoke([Action]{}, 'Background')
      Start-Sleep -Seconds 1
    }
    $window.Close()
  }

  # unblock user input
  $null = $userInput::ShowCursor($true)
  $null = $userInput::BlockInput($false)
}
```

请注意 `Lock-Screen` 需要管理员权限才能完全禁止用户输入。

<!--本文国际来源：[Locking the Screen with PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/locking-the-screen-with-powershell)-->

