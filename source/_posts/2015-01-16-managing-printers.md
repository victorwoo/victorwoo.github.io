layout: post
date: 2015-01-16 12:00:00
title: "PowerShell 技能连载 - 管理打印机"
description: PowerTip of the Day - Managing Printers
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
_适用于 Windows 8.1 和 Server 2012 R2_

Windows 8.1 和 Server 2012 R2 带来了一个叫做“PrintManagement”的模块。它包含了管理本地和远程打印机所需的所有 Cmdlet。

以下是一个示例脚本，演示了安装打印机驱动、设置打印机端口、安装打印机、共享该打印机，以及设置某些打印机属性的过程。

    $ComputerName = $env:COMPUTERNAME 
    
    $DriverName = 'Samsung SCX-483x 5x3x Series XPS'
    $IPAddress = '192.168.2.107'
    $PortName = 'NetworkPrint_192.168.2.107'
    $PrinterName = 'BWPrint'
    $ShareName = 'Office 12'
    
    Add-PrinterDriver -ComputerName $ComputerName -Name $DriverName
    Add-PrinterPort -Name $PortName -ComputerName $ComputerName 
    Add-Printer -ComputerName $ComputerName -Name $PrinterName -DriverName $DriverName -Shared -ShareName $ShareName -PortName $PortName
    Set-PrintConfiguration -ComputerName $ComputerName -PrinterName $PrinterName -PaperSize A4 

要使用它，请确保您修改了 `$IPAddress` 并指向一个存在的打印机。请将 `$ComputerName` 修改指向一个远程计算机而不是您的本地计算机。

要列出 `PrintManagement` 模块所带的所有 Cmdlet，请试试以下代码：

    PS> Get-Command -Module PrintManagement
    
    CommandType     Name                                               ModuleName                                               
    -----------     ----                                               ----------                                               
    Function        Add-Printer                                        PrintManagement                                          
    Function        Add-PrinterDriver                                  PrintManagement                                          
    Function        Add-PrinterPort                                    PrintManagement                                          
    Function        Get-PrintConfiguration                             PrintManagement                                          
    Function        Get-Printer                                        PrintManagement                                          
    Function        Get-PrinterDriver                                  PrintManagement                                          
    Function        Get-PrinterPort                                    PrintManagement                                          
    Function        Get-PrinterProperty                                PrintManagement                                          
    Function        Get-PrintJob                                       PrintManagement                                          
    Function        Read-PrinterNfcTag                                 PrintManagement                                          
    Function        Remove-Printer                                     PrintManagement                                          
    Function        Remove-PrinterDriver                               PrintManagement                                          
    Function        Remove-PrinterPort                                 PrintManagement                                          
    Function        Remove-PrintJob                                    PrintManagement                                          
    Function        Rename-Printer                                     PrintManagement                                          
    Function        Restart-PrintJob                                   PrintManagement                                          
    Function        Resume-PrintJob                                    PrintManagement                                          
    Function        Set-PrintConfiguration                             PrintManagement                                          
    Function        Set-Printer                                        PrintManagement                                          
    Function        Set-PrinterProperty                                PrintManagement                                          
    Function        Suspend-PrintJob                                   PrintManagement                                          
    Function        Write-PrinterNfcTag                                PrintManagement

如您所见，它们实际上是 PowerShell 函数而不是二进制 Cmdlet。

<!--more-->
本文国际来源：[Managing Printers](http://powershell.com/cs/blogs/tips/archive/2015/01/16/managing-printers.aspx)
