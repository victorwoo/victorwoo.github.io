layout: post
date: 2015-02-10 12:00:00
title: "PowerShell 技能连载 - 查找 AD 复制失败信息"
description: 'PowerTip of the Day - Find AD Replication Failures '
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
_适用于 Windows 8.1、Server 2012 R2_

在 Windows 8.1 和 Server 2012 R2 中，查看 Active Directory 复制失败的信息变得更简单了。`Get-ADReplicationFailure` 这个新的 cmdlet 将会输出最近的复制失败信息。用它来检查一个特定的域控制器的方法：

    PS> Get-ADReplicationFailure dc1.test.com

或者检查整个站点：

    PS> Get-ADReplicationFailure -Scope Site -Target Hannover

该 cmdlet 是随 Windows 8.1 和 Server 2012 R2 发布的 `ActiveDirectory` 模块的一部分。在您使用它之前，请确保您在控制面板/软件/启用或关闭 Windows 功能中启用了它。它是“远程服务器管理工具 (RSAT)”的一部分。如果您的 Windows 8.1 没有预装 RSAT，您可以从这里下载它：http://www.microsoft.com/de-de/download/details.aspx?id=39296。

要查看该模块提供的其它 cmdlet，请试试这行代码：

    PS> Get-Command -Module ActiveDirectory
    
    CommandType     Name                                               ModuleName  
    -----------     ----                                               ----------  
    Cmdlet          Add-ADCentralAccessPolicyMember                    ActiveDir...
    Cmdlet          Add-ADComputerServiceAccount                       ActiveDir...
    Cmdlet          Add-ADDomainControllerPasswordReplicationPolicy    ActiveDir...
    Cmdlet          Add-ADFineGrainedPasswordPolicySubject             ActiveDir...
    (...)

请注意针对 Windows 8.1/Server 2012 R2 的 RSAT提供了一些额外的 cmdlet，这些 cmdlet 在针对 Windows 早期版本的 RSAT 中并没有提供。

<!--more-->
本文国际来源：[Find AD Replication Failures ](http://powershell.com/cs/blogs/tips/archive/2015/02/10/find-ad-replication-failures.aspx)
