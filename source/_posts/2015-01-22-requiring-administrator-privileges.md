layout: post
date: 2015-01-22 12:00:00
title: "PowerShell 技能连载 - 要求管理员权限"
description: PowerTip of the Day - Requiring Administrator Privileges
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
_适用于 PowerShell 4.0 及以上版本_

如果您知道某个脚本需要管理员权限，只需要一个简单的 `#requres` 语句就可以确保符合该需求的才可以运行：

    #requires -version 4.0
    #requires –runasadministrator
    
    
    'I am Admin!' 

如果这个脚本没有使用管理员身份运行，它将显示一个有意义错误提示信息，说明它为何无法运行。

实际上，在这个例子中您可以看到两条 `#requires` 语句。第一条确保该脚本至少运行在 PowerShell 4.0 以上的环境中，这是第二条 `#requires` 的先决条件。它是由 PowerShell 4.0 引入的，不支持 PowerShell 更低的版本。

所以最好不要在 PowerShell 3.0 或更早的环境中使用这个技术。在那些环境中，您还是需要手工确认脚本是否拥有管理员权限。

<!--more-->
本文国际来源：[Requiring Administrator Privileges](http://community.idera.com/powershell/powertips/b/tips/posts/requiring-administrator-privileges)
