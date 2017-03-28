layout: post
title: "PowerShell 技能连载 - 锁定屏幕"
date: 2013-12-12 00:00:00
description: PowerTip of the Day - Use a Lock Screen
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
借助 WPF，PowerShell 用几行代码就可以创建窗口。以下是一个有趣的关于透明屏幕覆盖层的例子。

您可以调用 `Lock-Screen` 并且传入一个脚本块和一个标题。PowerShell 将会用它的覆盖层锁定屏幕，再次执行代码将解锁。

	function Lock-Screen([ScriptBlock] $Payload={Start-Sleep -Seconds 5}, $Title='Busy, go away.')
	{
	    try
	    {
	      $window = New-Object Windows.Window
	      $label = New-Object Windows.Controls.Label
	
	      $label.Content = $Title
	      $label.FontSize = 60
	      $label.FontFamily = 'Consolas'
	      $label.Background = 'Transparent'
	      $label.Foreground = 'Red'
	      $label.HorizontalAlignment = 'Center'
	      $label.VerticalAlignment = 'Center'
	
	      $Window.AllowsTransparency = $True
	      $Window.Opacity = .7
	      $window.WindowStyle = 'None'
	      $window.Content = $label
	      $window.Left = $window.Top = 0
	      $window.WindowState = 'Maximized'
	      $window.Topmost = $true
	
	      $null = $window.Show()
	      Invoke-Command -ScriptBlock $Payload
	    }
	    finally { $window.Close() }
	}
	
	$job =
	{
	  Get-ChildItem c:\windows -Recurse -ErrorAction SilentlyContinue
	}
	
	Lock-Screen -Payload $job -Title 'I am busy, go away and grab a coffee...'

您很快就会发现，锁屏确实可以防止鼠标点击，但是并不会屏蔽按键。这是一个有趣的技术，不是绝对安全的锁定。

<!--more-->
本文国际来源：[Use a Lock Screen](http://community.idera.com/powershell/powertips/b/tips/posts/use-a-lock-screen)
