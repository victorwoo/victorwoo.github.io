---
layout: post
date: 2019-12-26 00:00:00
title: "PowerShell 技能连载 - 列出已安装的更新（第 2 部分）"
description: PowerTip of the Day - Listing Installed Updates (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何通过 Windows Update 客户端获取当前已安装的更新。

可以对此列表进行润色，例如您可以使用哈希表创建计算的属性，提取默认情况下属于其他属性的信息，如知识库文章编号作为标题：

```powershell
$severity = @{
  Name = 'Severity'
  Expression = { if ([string]::IsNullOrEmpty($_.MsrcSeverity)) { 'normal' } else { $_.MsrcSeverity }}
}

$time = @{
  Name = 'Time'
  Expression = { $_.LastDeploymentChangeTime }
}

$kb = @{
  Name = 'KB'
  Expression = { if ($_.Title -match 'KB\d{6,9}') { $matches[0] } else { 'N/A' }}
}

$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSession.CreateupdateSearcher().Search("IsInstalled=1").Updates |
  Select-Object $time, Title, $kb, Description, $Severity |
  Out-GridView -Title 'Installed Updates'
```

结果显示在一个网格视图窗口中。如果您移除了 `Out-GridView` 那么信息看起来类似这样：

    Time        : 9/10/2019 12:00:00 AM
    Title       : 2019-09 Security Update for Adobe Flash Player for Windows 10 Version 1903 for
                  x64-based Systems (KB4516115)
    KB          : KB4516115
    Description : A security issue has been identified in a Microsoft software product that could
                  affect your system. You can help protect your system by installing this update
                  from Microsoft. For a complete listing of the issues that are included in this
                  update, see the associated Microsoft Knowledge Base article. After you install
                  this update, you may have to restart your system.
    Severity    : Critical

    Time        : 10/8/2019 12:00:00 AM
    Title       : Windows Malicious Software Removal Tool x64 - October 2019 (KB890830)
    KB          : KB890830
    Description : After the download, this tool runs one time to check your computer for infection by specific, prevalent malicious software (including Blaster, Sasser,
    and Mydoom) and helps remove any infection that is found. If an infection is found, the tool will display a status report the next time that you start your computer. A new version of the tool will be offered every month. If you want to manually run the tool on your computer, you can download a copy from the Microsoft Download Center, or you can run an online version from microsoft.com. This tool is not a replacement for an antivirus product. To help protect your computer, you should use an antivirus product.
    Severity    : normal

    Time        : 10/8/2019 12:00:00 AM
    Title       : 2019-10 Cumulative Update for .NET Framework 3.5 and 4.8 for Windows 10 Version
                  1903 for x64 (KB4524100)
    KB          : KB4524100
    Description : Install this update to resolve issues in Windows. For a complete listing of the issues that are included in this update, see the associated Microsoft Knowledge Base article for more information. After you install this item, you may have to restart your computer.
    Severity    : normal

    Time        : 10/28/2019 12:00:00 AM
    Title       : Update for Windows Defender Antivirus antimalware platform - KB4052623 (Version 4.18.1910.4)
    KB          : KB4052623
    Description : This package will update Windows Defender Antivirus antimalware platform’s components on the user machine.
    Severity    : normal

    ...

<!--本文国际来源：[Listing Installed Updates (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/listing-installed-updates-part-2)-->

