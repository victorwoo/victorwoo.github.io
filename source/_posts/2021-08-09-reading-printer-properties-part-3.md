---
layout: post
date: 2021-08-09 00:00:00
title: "PowerShell 技能连载 - 读取打印机属性（第 3 部分）"
description: PowerTip of the Day - Reading Printer Properties (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中，我们研究了如何使用 `Get-PrinterProperty` 读取本地安装打印机的打印机属性。此 cmdlet 是所有 Windows 操作系统附带的 `PrintManagement` 模块的一部分。

重要提示：由于属性名称是特定于打印驱动程序的，如果您需要在整个企业中管理相同类型的打印机，此 cmdlet 会非常有用。如果您想为大量不同的打印机类型创建详细的打印机清单，这不是最佳选择，因为您必须为每个正在使用的打印机驱动程序确定确切的属性名称。同样，在下面的示例中，请确保将打印机属性名称替换为您的打印机支持的名称。

简而言之，要读取特定的打印机属性，您需要提供打印机的名称（运行 `Get-Printer` 以查找打印机名称）。然后该 cmdlet 会列出所有可用的打印机属性，这些属性可能会因打印机驱动程序和型号而异：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP'

ComputerName         PrinterName          PropertyName         Type       Value
------------         -----------          ------------         ----       -----
                        S/W Laser HP         Config:AccessoryO... String     500Stapler
                        S/W Laser HP         Config:ActualCust... String     431800_914400
                        S/W Laser HP         Config:AutoConfig... String     NotInstalled
                        S/W Laser HP         Config:Auto_install  String     INSTALLED
                        S/W Laser HP         Config:BookletMak... String     NOTINSTALLED
                        S/W Laser HP         Config:CombineMed... String     Installed
                        S/W Laser HP         Config:DeviceIsMo... String     Installed
                        S/W Laser HP         Config:DuplexUnit    String     Installed
```

例如，您可以过滤属性名称并获取已安装和已卸载打印机附件的列表：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP' | Where-Object Value -like *installed* | Select-Object -Property PropertyName, Value

PropertyName                         Value
------------                         -----
Config:AutoConfiguration             NotInstalled
Config:Auto_install                  INSTALLED
Config:BookletMakerUnit_PC           NOTINSTALLED
Config:CombineMediaTypesAndInputBins Installed
Config:DeviceIsMopier                Installed
Config:DuplexUnit                    Installed
Config:EmbeddedJobAccounting         NotInstalled
Config:EnvFeed_install               NOTINSTALLED
Config:HPJobSeparatorPage            NotInstalled
Config:HPPinToPrintOnly              NotInstalled
Config:HPPunchUnitType               NotInstalled
Config:InsLwH1_install               NOTINSTALLED
Config:InsUpH1_install               NOTINSTALLED
Config:JobRetention                  Installed
Config:ManualFeed_install            INSTALLED
Config:PCCFoldUnit                   NOTINSTALLED
Config:PCVFoldUnit                   NOTINSTALLED
Config:PrinterHardDisk               Installed
Config:SecurePrinting                Installed
Config:StaplingUnit_PC               NOTINSTALLED
Config:Tray10_install                NOTINSTALLED
Config:Tray1_install                 INSTALLED
Config:Tray2_install                 INSTALLED
Config:Tray3_install                 INSTALLED
Config:Tray4_install                 NOTINSTALLED
Config:Tray5_install                 NOTINSTALLED
Config:Tray6_install                 NOTINSTALLED
Config:Tray7_install                 NOTINSTALLED
Config:Tray8_install                 NOTINSTALLED
Config:Tray9_install                 NOTINSTALLED
Config:TrayExt1_install              NOTINSTALLED
Config:TrayExt2_install              NOTINSTALLED
Config:TrayExt3_install              NOTINSTALLED
Config:TrayExt4_install              NOTINSTALLED
Config:TrayExt5_install              NOTINSTALLED
Config:TrayExt6_install              NOTINSTALLED
```

知道打印机名称和特定属性名称后，您可以查询各个属性并检索值以在脚本中使用它。以下是检查是否安装了双面打印单元的示例（确保将打印机名称和属性名称调整为您的打印机型号）：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP' -PropertyName Config:DuplexUnit | Select-Object -ExpandProperty Value
Installed

PS> $hasDuplexUnit = (Get-PrinterProperty -PrinterName 'S/W Laser HP' -PropertyName Config:DuplexUnit).Value -eq 'installed'

PS> $hasDuplexUnit
True
```

要远程查询打印机，`Get-PrinterProperty` 具有 `-ComputerName` 参数。它接受单个字符串，因此您一次只能查询一台打印机，并且没有 `-Credential` 参数，因此您无法以其他人身份进行身份验证。你可以试试这个来查询你自己的机器，一旦成功，用真正的远程系统替换计算机名称：

```powershell
PS> Get-PrinterProperty -PrinterName 'S/W Laser HP' -ComputerName $env:COMPUTERNAME
```

由于 cmdlet 使用 Windows 远程管理服务进行远程访问，因此目标打印服务器应启用 WinRM 远程处理（这是 Windows 服务器的默认设置），并且您应该是目标端的管理员。

实际情况中，您还希望能够查询多个服务器并以其他人身份进行身份验证。对于远程访问，首先使用 `New-CimSession` 指定要查询的所有服务器，并根据需要提交凭据。

接下来，将此会话提交给 `Get-PrinterProperty`。如果您有适当的访问权限，现在可以并行查询会话中的所有服务器，从而节省大量时间。`-ThrottleLimit` 参数确定最多实际联系多少个会话。如果您指定的服务器数超过最大连接数，PowerShell 将自动将其余服务器排队：

```powershell
$session = New-CimSession -ComputerName server1, server2, server3 -Credential mydomain\remotinguser

Get-PrinterProperty -PrinterName 'S/W Laser HP' -CimSession $session -ThrottleLimit 100

Remove-CimSession -CimSession $session
```

额外提示：您也可以使用 `Get-Printer` 查找远程打印机名称。`Get-Printer` 还接受 `-CimSession` 参数，因此您可以使用相同的网络会话从一台或多台远程服务器查询所有打印机名称。
<!--本文国际来源：[Reading Printer Properties (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-printer-properties-part-3)-->

