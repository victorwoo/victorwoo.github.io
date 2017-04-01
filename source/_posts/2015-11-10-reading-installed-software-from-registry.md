layout: post
date: 2015-11-10 12:00:00
title: "PowerShell 技能连载 - 从注册表中读取已安装的软件"
description: PowerTip of the Day - Reading Installed Software from Registry
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
以下是查看已安装的软件的快速方法。`Get-Software` 函数读取所有用户的 32 位和 64 位软件的安装地址。

    #requires -Version 1
    
    function Get-Software
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

它甚至包含了过滤参数，所以您可以当您指定 `-DisplayName` 或 `-UninstallString`（或两者）时，您可以轻松地过滤结果，仅显示您期望的软件产品。两个参数都支持通配符。

以下是一个调用的示例，显示所有的 Office 组件到一个网格视图窗口中：

    Get-Software -DisplayName *Office* | Out-GridView

<!--more-->
本文国际来源：[Reading Installed Software from Registry](http://community.idera.com/powershell/powertips/b/tips/posts/reading-installed-software-from-registry)
