layout: post
date: 2015-03-25 11:00:00
title: "PowerShell 技能连载 - 使用常量"
description: PowerTip of the Day - Using Constants
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
_适用于 PowerShell 所有版本_

PowerShell 中的变量是不稳定的。您可以覆盖或是删除它们——除非创建常量。

常量只能在还不存在该常量的时候创建。这行代码创建了一个名为“_connotChange_”，值为 1 的常量。

    New-Variable -Name cannotChange -Value 1 -Option Constant

在 PowerShell 运行期间，无法删除这个变量。该变量被绑定到当前的 PowerShell 会话。常量可以用在您不希望改变的敏感信息上。

您可以在您的主配置文件路径上定义常量，例如：

    PS> $profile.AllUsersAllHosts
    C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1                                                 

如果该文件存在，PowerShell 将会在任何实例启动之前先执行它。如果您在此定义了常量——例如您的公司名、重要的服务器列表等——该信息将在所有 PowerShell 宿主内有效，而且无法被覆盖。

<!--more-->
本文国际来源：[Using Constants](http://community.idera.com/powershell/powertips/b/tips/posts/using-constants)
