---
layout: post
date: 2015-06-11 11:00:00
title: "PowerShell 技能连载 - 安装 Windows 功能"
description: PowerTip of the Day - Installing Windows Features
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
在服务器中，Powershell 可以通过 `Install-WindowsFeature` 命令安装 Windows 功能。

若您将 `Install-WindowsFeature` 返回的结果保存下来，则可以用 `Get-WindowsFeature` 查看安装的状态：

    # install features on server and save result in $result
    Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools -OutVariable result -Verbose
    
    # view the result of your change
    Get-WindowsFeature -Name $result.FeatureResult.Name

<!--more-->
本文国际来源：[Installing Windows Features](http://community.idera.com/powershell/powertips/b/tips/posts/installing-windows-features)
