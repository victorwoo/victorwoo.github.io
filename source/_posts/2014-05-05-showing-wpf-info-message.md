---
layout: post
title: "PowerShell 技能连载 - 显示 WPF 消息提示"
date: 2014-05-05 00:00:00
description: PowerTip of the Day - Showing WPF Info Message
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
WPF (Windows Presentation Foundation) 是一种创建窗体和对话框的技术。WPF 的好处是窗体设计和程序代码可以分离。

以下是一个显示醒目消息的例子。消息内容定义在 XAML 代码中，看起来类似 HTML （不过是区分大小写的）。您可以很容易地调整字体大小、文字、颜色等。不需要改任何程序代码：

    $xaml = @"
    <Window
     xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'>
    
     <Border BorderThickness="20" BorderBrush="Yellow" CornerRadius="9" Background='Red'>
      <StackPanel>
       <Label FontSize="50" FontFamily='Stencil' Background='Red' Foreground='White' BorderThickness='0'>
        System will be rebooted in 15 minutes!
       </Label>
    
       <Label HorizontalAlignment="Center" FontSize="15" FontFamily='Consolas' Background='Red' Foreground='White' BorderThickness='0'>
        Worried about losing data? Talk to your friendly help desk representative and freely share your concerns!
       </Label>
      </StackPanel>
     </Border>
    </Window>
    "@
    
    $reader = [System.XML.XMLReader]::Create([System.IO.StringReader] $xaml)
    $window = [System.Windows.Markup.XAMLReader]::Load($reader)
    $Window.AllowsTransparency = $True
    $window.SizeToContent = 'WidthAndHeight'
    $window.ResizeMode = 'NoResize'
    $Window.Opacity = .7
    $window.Topmost = $true
    $window.WindowStartupLocation = 'CenterScreen'
    $window.WindowStyle = 'None'
    # show message for 5 seconds:
    $null = $window.Show()
    Start-Sleep -Seconds 5
    $window.Close()

<!--more-->
本文国际来源：[Showing WPF Info Message](http://community.idera.com/powershell/powertips/b/tips/posts/showing-wpf-info-message)
