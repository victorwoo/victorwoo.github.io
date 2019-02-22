---
layout: post
date: 2018-03-09 00:00:00
title: "PowerShell 技能连载 - 备份事件日志"
description: PowerTip of the Day - Backing Up Event Logs
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有一系列有用的 cmdlet 可以管理事件日志，然而缺失了这个功能：

```powershell
PS> Get-Command -Noun EventLog

CommandType Name            Version Source
----------- ----            ------- ------
Cmdlet      Clear-EventLog  3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Get-EventLog    3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Limit-EventLog  3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      New-EventLog    3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Remove-EventLog 3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Show-EventLog   3.1.0.0 Microsoft.PowerShell.Management
Cmdlet      Write-EventLog  3.1.0.0 Microsoft.PowerShell.Management
```

没有一个将事件日志被分到 *.evtx 文件的 cmdlet。让我们动手编一个吧：

```powershell
function Backup-Eventlog
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $LogName,

        [Parameter(Mandatory)]
        [string]
        $DestinationPath
    )

    $eventLog = Get-WmiObject -Class Win32_NTEventLOgFile  -filter "FileName='$LogName'"
    if ($eventLog -eq $null)
    {
        throw "Eventlog '$eventLog' not found."
    }

    [int]$status = $eventLog.BackupEventlog($DestinationPath).ReturnValue
    New-Object -TypeName ComponentModel.Win32Exception($status)
}
```

现在备份事件日志变得十分方便，以下是一个使用示例：


```powershell
PS> Backup-Eventlog -LogName Application -DestinationPath c:\test\backup.evtx
The operation completed successfully

PS> Backup-Eventlog -LogName Application -DestinationPath c:\test\backup.evtx
The file exists

PS>
```

<!--本文国际来源：[Backing Up Event Logs](http://community.idera.com/powershell/powertips/b/tips/posts/backing-up-event-logs)-->
