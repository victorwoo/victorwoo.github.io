---
layout: post
date: 2018-05-11 00:00:00
title: "PowerShell 技能连载 - 创建 PowerShell 命令速查表（第 1 部分）"
description: PowerTip of the Day - Creating PowerShell Command Cheat Sheets (Part 1)
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
以下是一个创建您喜爱的 PowerShell 命令的速查表的的技巧。

所有 PowerShell 命令都是随着模块分发，所以如果您认为某个 PowerShell 对您有用，您可能希望列出模块中其它（可能相关）的命令。这行代码显示如何查找任何指定命令的模块名，并列出包含 `Get-WmiObject` 命令的模块名：

```powershell
PS>
PS> (Get-Command -Name Get-WmiObject).ModuleName
Microsoft.PowerShell.Management
```

要查看这个模块所有其它命令，请试试这段代码：

```powershell
PS> Get-Command -Module Microsoft.PowerShell.Management

CommandType     Name                                               Version
-----------     ----                                               -------
Cmdlet          Add-Computer                                       3.1.0.0
Cmdlet          Add-Content                                        3.1.0.0
Cmdlet          Checkpoint-Computer                                3.1.0.0
Cmdlet          Clear-Content                                      3.1.0.0
Cmdlet          Clear-EventLog                                     3.1.0.0
Cmdlet          Clear-Item                                         3.1.0.0
Cmdlet          Clear-ItemProperty                                 3.1.0.0
Cmdlet          Clear-RecycleBin                                   3.1.0.0
```

要创建一个包含命令名和描述的便利的速查表，请将命令通过管道导出到 `Get-Help` 命令，然后使用 `Select-Object` 从帮助中选择详细信息，加入您的速查表：

```powershell
PS> Get-Command -Module Microsoft.PowerShell.Management | Get-Help | Select-Object -Property Name, Synopsis

Name                Synopsis
----                --------
Add-Computer        Add the local computer to a domain or workgroup.
Add-Content         Adds content to the specified items, such as adding word...
Checkpoint-Computer Creates a system restore point on the local computer.
Clear-Content       Deletes the contents of an item, but does not delete the...
Clear-EventLog      Clears all entries from specified event logs on the loca...
Clear-Item          Clears the contents of an item, but does not delete the ...
Clear-ItemProperty  Clears the value of a property but does not delete the p...
Clear-RecycleBin
Complete-Transac... Commits the active transaction.
Convert-Path        Converts a path from a Windows PowerShell path to a Wind...
Copy-Item           Copies an item from one location to another.
Copy-ItemProperty   Copies a property and value from a specified location to...
Debug-Process       Debugs one or more processes running on the local computer.
Disable-Computer... Disables the System Restore feature on the specified fil...
Enable-ComputerR... Enables the System Restore feature on the specified file...
Get-ChildItem       Gets the items and child items in one or more specified ...
Get-Clipboard       Gets the current Windows clipboard entry.
Get-ComputerInfo    Gets a consolidated object of system and operating syste...
Get-ComputerRest... Gets the restore points on the local computer.
Get-Content         Gets the content of the item at the specified location.
Get-ControlPanel... Gets control panel items.
Get-EventLog        Gets the events in an event log, or a list of the event ...
Get-HotFix          Gets the hotfixes that have been applied to the local an...
Get-Item            Gets the item at the specified location.
Get-ItemProperty    Gets the properties of a specified item.
Get-ItemProperty... Gets the value for one or more properties of a specified...
Get-Location        Gets information about the current working location or a...
```

如果帮助信息不完整，并且没有选择的命令没有提要信息，那么您可能首先需要下载 PowerShell 帮助。要下载帮助，首先需要一个提升权限的 PowerShell：


```powershell
PS> Update-Help -UICulture en-us -Force
```

不要担心这条命令抛出的错误信息：它对于一小部分没有提供帮助信息的模块是正常的。如果您收到一大堆错误信息，那么您可能没有在提升权限的 PowerShell 中执行命令。不幸的是，PowerShell 存储帮助文件的位置和模块的位置不同，普通用户不可存存储取帮助文件的位置。

<!--more-->
本文国际来源：[Creating PowerShell Command Cheat Sheets (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-powershell-command-cheat-sheets-part-1)
