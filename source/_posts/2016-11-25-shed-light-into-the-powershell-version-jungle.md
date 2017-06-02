---
layout: post
date: 2016-11-25 00:00:00
title: "PowerShell 技能连载 - 轻轻跳进 PowerShell 版本的丛林"
description: PowerTip of the Day - Shed Light into the PowerShell Version Jungle
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
PowerShell 同时有五个主要版本在发行。除掉最新的小版本，例如 Windows 10 和 Server 2016 上的 PowerShell 5.1。加上 beta 版和预发行版本，以及 Linux 和 Nano 服务器上的 PowerShell。哇哦！

要跟踪这些版本，并知道正在用哪个版本、它从哪里来、可能有哪些兼容性问题很不容易。MVP 大学里的 Egil Ring 维护着一个很酷的模块。如果您装了 PowerShell 5 或从 powershellgallery.com 安装了 PowerShellGet，您可以用一行代码下载这个模块：

```powershell
PS C:\> Install-Module -Name PSVersion -Scope CurrentUser 
```

回答几个问题后，该模块安装完成。它只包含两个命令：

```powershell
PS C:\> Get-Command -Module PSVersion

CommandType     Name                        Version    Source                                        
-----------     ----                        -------    ------                                        
Function        Get-PSVersion               1.6        PSVersion                                     
Function        Update-PSVersionData        1.6        PSVersion 
```

PSVersion 是一个社区项目，跟踪 PowerShell 的发行编号、它们的含义、它们的来源：

```powershell
PS C:\> Get-PSVersion -ListVersion

Name           FriendlyName                                 ApplicableOS            
----           ------------                                 ------------            
5.1.14393.0    Windows PowerShell 5.1 Preview               Windows 10 Anniversar...
5.1.14300.1000 Windows PowerShell 5.1 Preview               Windows Server 2016 T...
5.0.10586.494  Windows PowerShell 5 RTM                     Windows 10 1511 + KB3...
5.0.10586.122  Windows PowerShell 5 RTM                     Windows 10 1511 + KB3...
5.0.10586.117  Windows PowerShell 5 RTM 1602                Windows Server 2012 R...
5.0.10586.63   Windows PowerShell 5 RTM                     Windows 10 1511 + KB3...
5.0.10586.51   Windows PowerShell 5 RTM 1512                Windows Server 2012 R...
5.0.10514.6    Windows PowerShell 5 Production Preview 1508 Windows Server 2012 R2  
5.0.10018.0    Windows PowerShell 5 Preview 1502            Windows Server 2012 R2  
5.0.9883.0     Windows PowerShell 5 Preview November 2014   Windows Server 2012 R...
4.0            Windows PowerShell 4 RTM                     Windows Server 2012 R...
3.0            Windows PowerShell 3 RTM                     Windows Server 2012, ...
2.0            Windows PowerShell 2 RTM                     Windows Server 2008 R...
1.0            Windows PowerShell 1 RTM                     Windows Server 2008, ...
```

这是在您的企业中以友好的 PowerShell 版本名称获得 PowerShell 版本号的方法：

```powershell
PS C:\> Get-PSVersion 

PSComputerName  PSVersion     PSVersionFriendlyName
--------------  ---------     ---------------------
CLIENT12        5.1.14393.0   Windows PowerShell 5.1 Preview
```

<!--more-->
本文国际来源：[Shed Light into the PowerShell Version Jungle](http://community.idera.com/powershell/powertips/b/tips/posts/shed-light-into-the-powershell-version-jungle)
