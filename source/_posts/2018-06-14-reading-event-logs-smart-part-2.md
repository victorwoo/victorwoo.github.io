---
layout: post
date: 2018-06-14 00:00:00
title: "PowerShell 技能连载 - 巧妙地读取事件日志（第 2 部分）"
description: PowerTip of the Day - Reading Event Logs Smart (Part 2)
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
在前一个技能中我们演示了如何使用 `ReplacementStrings` 读取从 `Get-EventLog` 中收到的详细的事件日志信息。它工作得很完美，但是 `Get-EventLog` 职能读取“传统的”Windows 日志。在现代的 Windows 版本中还有许多额外的日志。

这些日志可以通过 `Get-WinEvent` 读取，而且有许多信息可以发掘。例如，要获取已安装的更新列表，请试试这段代码：

```powershell
$filter = @{ ProviderName="Microsoft-Windows-WindowsUpdateClient"; Id=19 }

Get-WinEvent -FilterHashtable $filter | Select-Object -ExpandProperty Message -First 4
```

请注意这只是一个例子。通过以上代码，您可以查询您关心的任意事件 ID 的日志。例如以上代码，可以获取最新安装的 4 条更新：

```powershell
PS> . 'C:\Users\tobwe\Documents\PowerShell\Untitled5.ps1' <# script is not saved yet #>
Installation Successful: Windows successfully installed the following update: Definitionsupdate für
    Windows Defender Antivirus – KB2267602 (Definition 1.269.69.0)
Installation Successful: Windows successfully installed the following update: 9WZDNCRFJ1XX-FITBIT.F
ITBIT
Installation Successful: Windows successfully installed the following update: Definitionsupdate für
    Windows Defender Antivirus – KB2267602 (Definition 1.269.28.0)
Installation Successful: Windows successfully installed the following update: 9WZDNCRFHVQM-MICROSOF
T.WINDOWSCOMMUNICATIONSAPPS   
```

然而，这只是文本，而且要将它转换为一份已安装的更新的漂亮的报告并不容易。通过 `Get-EventLog`，类似我们之前的技能介绍的，您可以使用 `ReplacementStrings` 来方便地存取纯净的信息。但是 `Get-WinEvent` 没有 `ReplacementStrings`。

然而，有一个名为 `Properties` 的属性。以下是如何将属性转换为类似 `ReplacementStrings` 的数组的方法：

```powershell
$filter = @{ ProviderName="Microsoft-Windows-WindowsUpdateClient"; Id=19 }

Get-WinEvent -FilterHashtable $filter |  
    ForEach-Object {
    # create a ReplacementStrings array
    # this array holds the information that is inserted
    # into the event message template text
    $ReplacementStrings = $_.Properties | ForEach-Object { $_.Value }
    
    # return a new object with the required information
    [PSCustomObject]@{
        Time = $_.TimeCreated
        # index 0 contains the name of the update
        Name = $ReplacementStrings[0]
        User = $_.UserId.Value
    }
    }
```

这段代码返回以安装更新的美观的列表：

    Time                Name
    ----                ----
    25.05.2018 09:00:20 Definitionsupdate für Windows Defender Antivirus – KB2267602 (Definition 1....
    25.05.2018 07:59:44 9WZDNCRFJ1XX-FITBIT.FITBIT                                                    
    24.05.2018 11:04:15 Definitionsupdate für Windows Defender Antivirus – KB2267602 (Definition 1....
    24.05.2018 08:36:26 9WZDNCRFHVQM-MICROSOFT.WINDOWSCOMMUNICATIONSAPPS                              
    24.05.2018 08:34:30 9N4WGH0Z6VHQ-Microsoft.HEVCVideoExtension                                     
    24.05.2018 08:34:24 9WZDNCRFJ2QK-ZDFGemeinntzigeAnstaltdes.ZDFmediathek                           
    23.05.2018 11:57:42 Definitionsupdate für Windows Defender Antivirus – KB2267602 (Definition 1....
    23.05.2018 07:37:11 9WZDNCRFHVQM-MICROSOFT.WINDOWSCOMMUNICATIONSAPPS                              
    23.05.2018 07:36:57 9WZDNCRFJ3PT-MICROSOFT.ZUNEMUSIC                                              
    23.05.2018 04:01:11 Definitionsupdate für Windows Defender Antivirus – KB2267602 (Definition 1....
    22.05.2018 12:26:55 Definitionsupdate für Windows Defender Antivirus – KB2267602 (Definition 1....
    22.05.2018 08:34:28 9NBLGGH5FV99-Microsoft.MSPaint                                                
    22.05.2018 08:33:25 9WZDNCRFJ364-MICROSOFT.SKYPEAPP

<!--more-->
本文国际来源：[Reading Event Logs Smart (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-event-logs-smart-part-2)
