---
layout: post
date: 2015-11-11 12:00:00
title: "PowerShell 技能连载 - 远程获取已安装的软件列表"
description: PowerTip of the Day - Getting Installed Software Remotely
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中，我们介绍了 `Get-Software` 函数，它可以获取本地计算机已安装的软件。

如果您在远程系统上已经安装了 PowerShell 远程操作（在 Windows Server 2012 及以上版本中默认是开启的），并且如果您拥有合适的权限，请试试这个增强的版本。它同时支持本地和远程调用：

    #requires -Version 2

    function Get-Software
    {
        param
        (
            [string]
            $DisplayName='*',

            [string]
            $UninstallString='*',

            [string[]]
            $ComputerName
        )

        [scriptblock]$code =
        {

            param
            (
            [string]
            $DisplayName='*',

            [string]
            $UninstallString='*'

            )
          $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
           'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

          Get-ItemProperty -Path $keys |
          Where-Object { $_.DisplayName } |
          Select-Object -Property DisplayName, DisplayVersion, UninstallString |
          Where-Object { $_.DisplayName -like $DisplayName } |
          Where-Object { $_.UninstallString -like $UninstallString }

        }
        if ($PSBoundParameters.ContainsKey('ComputerName'))
        {
        Invoke-Command -ScriptBlock $code -ComputerName $ComputerName -ArgumentList $DisplayName, $UninstallString
        }
        else
        {
            & $code -DisplayName $DisplayName -UninstallString $UninstallString
        }
    }

请注意这个函数如何将查找软件的代码包裹在代码块中。接下来，它将检测 `$PSBoundParameters` 来判断用户是否传入了 `-ComputerName` 参数。如果没有传入，该代码将在本地执行。

否则，`Invoke-Command` 将在指定的远程计算机（支持多台）上运行这段代码。在这个例子中，`Invoke-Command` 将过滤参数传递给远程代码。

<!--本文国际来源：[Getting Installed Software Remotely](http://community.idera.com/powershell/powertips/b/tips/posts/getting-installed-software-remotely)-->
