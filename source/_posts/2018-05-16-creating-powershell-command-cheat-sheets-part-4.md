---
layout: post
date: 2018-05-16 00:00:00
title: "PowerShell 技能连载 - 创建 PowerShell 命令速查表（第 4 部分）"
description: PowerTip of the Day - Creating PowerShell Command Cheat Sheets (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能里，我们创建了 PowerShell 命令的速查表。我们使用了它的名称和提要来创建速查表，类似这样：

```powershell
PS> Get-Command -Module "PrintManagement"|
    Get-Help |
    Select-Object -Property Name, Synopsis

Name                   Synopsis
----                   --------
Add-Printer            Adds a printer to the specified computer.
Add-PrinterDriver      Installs a printer driver on the specified computer.
Add-PrinterPort        Installs a printer port on the specified computer.
Get-PrintConfiguration Gets the configuration information of a printer.
Get-Printer            Retrieves a list of printers installed on a computer.
Get-PrinterDriver      Retrieves the list of printer drivers installed on...
Get-PrinterPort        Retrieves a list of printer ports installed on the...
Get-PrinterProperty    Retrieves printer properties for the specified pri...
Get-PrintJob           Retrieves a list of print jobs in the specified pr...
Read-PrinterNfcTag     Reads information about printers from an NFC tag.
Remove-Printer         Removes a printer from the specified computer.
Remove-PrinterDriver   Deletes printer driver from the specified computer.
Remove-PrinterPort     Removes the specified printer port from the specif...
Remove-PrintJob        Removes a print job on the specified printer.
...
```

`Get-Help` 返回的结果中有许多更有用的属性，例如 "`description`" 和 "`examples`"。不过它们看起来很奇怪，好像装在一个哈希表中一样：

```powershell
PS> Get-Command -Module "PrintManagement"|
    Get-Help |
    Select-Object -Property Name, Description

Name                   description
----                   -----------
Add-Printer            {@{Text=The Add-Printer cmdlet adds a printer to a specified computer. Y...
Add-PrinterDriver      {@{Text=The Add-PrinterDriver cmdlet installs a printer driver on the sp...
Add-PrinterPort        {@{Text=The Add-PrinterPort cmdlet creates a printer port on the specifi...
Get-PrintConfiguration {@{Text=The Get-PrintConfiguration cmdlet gets the configuration informa...
Get-Printer            {@{Text=The Get-Printer cmdlet retrieves a list of printers installed on...
Get-PrinterDriver      {@{Text=The Get-PrinterDriver cmdlet retrieves the list of printer drive...
Get-PrinterPort        {@{Text=The Get-PrinterPort cmdlet retrieves a list of printer ports tha...
Get-PrinterProperty    {@{Text=The Get-PrinterProperty cmdlet retrieves one or more printer pro...
Get-PrintJob           {@{Text=The Get-PrintJob cmdlet retrieves the current print jobs in the ...
Read-PrinterNfcTag     {@{Text=The Read-PrinterNfcTag cmdlet reads information about printers f...
Remove-Printer         {@{Text=The Remove-Printer cmdlet deletes a printer from the specified c...
Remove-PrinterDriver   {@{Text=The Remove-PrinterDriver cmdlet deletes a printer driver from th...
Remove-PrinterPort     {@{Text=The Remove-PrinterPort cmdlet removes the specified printer port...
...
```

这是因为类似 "Description" 的属性包含了一个名为 "`Text`" 的属性，它是一个数组（支持多行文本）。要获取纯文本，您需要手工从属性获取信息，类似这样：

```powershell
# adjust the name of the module
# code will list all commands shipped by that module
# list of all modules: Get-Module -ListAvailable
$ModuleName = "PrintManagement"

$Description = @{
    Name = "Description"
    Expression = { $_.Description.Text -join " " }
}

Get-Command -Module $moduleName |
    Get-Help |
    Select-Object -Property Name, $Description
```

现在结果看起来和预期相符了：

```powershell
Name                   Description
----                   -----------
Add-Printer            The Add-Printer cmdlet adds a printer to a specified ...
Add-PrinterDriver      The Add-PrinterDriver cmdlet installs a printer drive...
Add-PrinterPort        The Add-PrinterPort cmdlet creates a printer port on ...
Get-PrintConfiguration The Get-PrintConfiguration cmdlet gets the configurat...
Get-Printer            The Get-Printer cmdlet retrieves a list of printers i...
Get-PrinterDriver      The Get-PrinterDriver cmdlet retrieves the list of pr...
Get-PrinterPort        The Get-PrinterPort cmdlet retrieves a list of printe...
Get-PrinterProperty    The Get-PrinterProperty cmdlet retrieves one or more ...
Get-PrintJob           The Get-PrintJob cmdlet retrieves the current print j...
Read-PrinterNfcTag     The Read-PrinterNfcTag cmdlet reads information about...
Remove-Printer         The Remove-Printer cmdlet deletes a printer from the ...
Remove-PrinterDriver   The Remove-PrinterDriver cmdlet deletes a printer dri...
Remove-PrinterPort     The Remove-PrinterPort cmdlet removes the specified p...
Remove-PrintJob        The Remove-PrintJob cmdlet removes a print job on the...
Rename-Printer         The Rename-Printer cmdlet renames the specified print...
Restart-PrintJob       The Restart-PrintJob cmdlet restarts a print job on t...
Resume-PrintJob        The Resume-PrintJob cmdlet resumes a suspended print ...
Set-PrintConfiguration The Set-PrintConfiguration cmdlet sets the printer co...
Set-Printer            The Set-Printer cmdlet updates the configuration of t...
```

<!--本文国际来源：[Creating PowerShell Command Cheat Sheets (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/creating-powershell-command-cheat-sheets-part-4)-->
