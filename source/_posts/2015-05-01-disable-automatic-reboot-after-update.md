layout: post
date: 2015-05-01 11:00:00
title: "PowerShell 技能连载 - 禁止更新后自动重启"
description: PowerTip of the Day - Disable Automatic Reboot After Update
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
您是否厌烦了 Windows 安装了一些更新后导致的非计划中的重启？

和其它情况类似，您可以通过组策略控制重启，而且多数组策略设置只是注册表键而已。以下是一个通过设置注册表键来实现控制安装更新后的重启设置的示例脚本：

    $code = 
    {
      $key = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
      $name = 'NoAutoRebootWithLoggedOnUsers'
      $type = 'DWord'
      $value = 1
    
      if (!(Test-Path -Path $key))
      {
        $null = New-Item -Path $key -Force
      }
      Set-ItemProperty -Path $key -Name $name -Value $value -Type $type
    }
    
    Start-Process -FilePath powershell.exe -ArgumentList $code -Verb runas -WorkingDirectory c:\

请注意该脚本如何操作注册表：它实际上是通过另一个 PowerShell 实例间接执行的。第二个实例是通过 `Start-Process` 启动的，而“`-Verb Runas`”确保了以管理员身份运行这段代码。

如果您当前没有管理员权限，那么会弹出提升权限的对话框供您选择使用管理员权限，或是如果您的账户没有管理员权限的时候要求您选择一个有权限的账户。

<!--more-->
本文国际来源：[Disable Automatic Reboot After Update](http://community.idera.com/powershell/powertips/b/tips/posts/disable-automatic-reboot-after-update)
