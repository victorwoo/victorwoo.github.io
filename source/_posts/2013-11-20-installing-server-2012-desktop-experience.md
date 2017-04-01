layout: post
title: "PowerShell 技能连载 - 安装 Windows Server 2012 桌面体验"
date: 2013-11-20 00:00:00
description: PowerTip of the Day - Installing Server 2012 Desktop Experience
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
如果您希望将 Windows Server 2012 （或 Windows Server 2008 R2）作为工作站机器使用并且使它看起来像 Windows 8（包括在文件浏览器中刻录 ISO 文件，以及个性化您的桌面和其它设置），您所需要做的只是添加桌面体验功能。以下是用 PowerShell 实现的方法：

	Add-WindowsFeature -Name Desktop-Experience

在 PowerShell 2.0 中，您首先需要手动导入合适的 module：

	Import-Module ServerManager

<!--more-->
本文国际来源：[Installing Server 2012 Desktop Experience](http://community.idera.com/powershell/powertips/b/tips/posts/installing-server-2012-desktop-experience)
