---
layout: post
date: 2021-02-24 00:00:00
title: "PowerShell 技能连载 - 查找 PowerShell 命令"
description: PowerTip of the Day - Finding PowerShell Commands
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
`Get-Command` 可以帮助您查找给定任务的 PowerShell 命令，但是此 cmdlet 只能搜索命令名称和参数中的关键字。

可以从 PowerShell Gallery 中安装更复杂的搜索命令：

```powershell
Install-Module -Name PSCommandDiscovery -Scope CurrentUser -Verbose
```

`Find-PowerShellCommand` 使用关键字并返回与此关键字相关的所有命令。它在命令名称，命令参数以及返回的对象属性中搜索关键字。如果找到的命令类型是已编译的应用程序，则该命令还将返回命令的类型（GUI 或基于控制台的命令）。

```powershell
PS> Find-PowerShellCommand -Keyword user -CommandType Function,Cmdlet,Application

Command                                   MatchType   Member
-------                                   ---------   ------
Add-WinADUserGroups                       CommandName
Get-ComputerInfo                          Property    [string] CsUserName (read/write)
Get-ComputerInfo                          Property    [Nullable`1[[System.UInt32, Syst…
Get-ComputerInfo                          Property    [Nullable`1[[System.UInt32, Syst…
Get-ComputerInfo                          Property    [string] OsRegisteredUser (read/…
Get-ComputerInfo                          Property    [Nullable`1[[Microsoft.PowerShel…
Get-Credential                            Property    [string] UserName (readonly)
Get-Culture                               Property    [bool] UseUserOverride (readonly)
Get-LocalUser                             CommandName
Get-PnPAADUser                            CommandName
Get-PnPTeamsUser                          CommandName
Get-PnPUser                               CommandName
Get-PnPUserOneDriveQuota                  CommandName
Get-PnPUserProfileProperty                CommandName
Get-Process                               Property    [timespan] UserProcessorTime (re…
Get-UICulture                             Property    [bool] UseUserOverride (readonly)
DevModeRunAsUserConfig.msc                Command     .msc: DevModeRunAsUserConfig (Un…
DsmUserTask.exe                           Command     .exe: DsmUserTask (x64) [Gui] 10…
quser.exe                                 Command     .exe: quser (x64) [Console] 10.0…
(...)
```

"`MatchType`" 属性报告匹配的种类。可以根据命令名称，参数名称或返回对象的任何属性名称中的关键字匹配找到命令。

有关其他示例，源代码和所有参数的说明，请参见 [https://github.com/TobiasPSP/PsCommandDiscovery](https://github.com/TobiasPSP/PsCommandDiscovery)。

<!--本文国际来源：[Finding PowerShell Commands](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-powershell-commands)-->
