---
layout: post
date: 2017-08-07 00:00:00
title: "PowerShell 技能连载 - 查找已安装和缺失的更新（第四部分）"
description: PowerTip of the Day - Finding Installed Updates (and searching for missing) (Part 4)
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
有些时候，`Microsoft.Update.Session` 对象可以用来检查一台机器上是否安装了某个更新。有些作者用这种方法查询更新的标题字符串：

```powershell
#requires -Version 3.0

function Get-UpdateInstalled([Parameter(Mandatory)]$KBNumber)
{
    $Session = New-Object -ComObject "Microsoft.Update.Session"
    $Searcher = $Session.CreateUpdateSearcher()
    $historyCount = $Searcher.GetTotalHistoryCount()

    $status = @{
        Name="Operation"
        Expression= {
            switch($_.operation)
            {
                1 {"Installation"}
                2 {"Uninstallation"}
                3 {"Other"}
            }
        }
    }

    $Searcher.QueryHistory(0, $historyCount) |
    Where-Object {$_.Title -like "*KB$KBNumber*" } |
    Select-Object -Property Title, $status, Date
}

function Test-UpdateInstalled([Parameter(Mandatory)]$KBNumber)
{
    $update = Get-UpdateInstalled -KBNumber $KBNumber |
    Where-Object Status -eq Installation |
    Select-Object -First 1

    return $update -ne $null
}

Test-UpdateInstalled -KBNumber 2267602
Get-UpdateInstalled -KBNumber 2267602 | Out-GridView
```

请注意这个方法不仅更快，而且由于它将任务分成两个函数，所以您还可以读出所有已安装的更新标题：

```powershell
PS> Get-UpdateInstalled -KBNumber 2267602

Title                                                                        Operation    Date
-----                                                                        ---------    ----
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.348.0)  Installation 28.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.281.0)  Installation 27.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.237.0)  Installation 26.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.191.0)  Installation 25.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.139.0)  Installation 24.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.95.0)   Installation 22.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.93.0)   Installation 22.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.28.0)   Installation 21.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.249.13.0)   Installation 20.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.247.1068.0) Installation 19.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.247.1010.0) Installation 18.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.247.969.0)  Installation 17.07.20...
Definitionsupdate für Windows Defender – KB2267602 (Definition 1.247.966.0)  Installation 17.07.20...
```

<!--more-->
本文国际来源：[Finding Installed Updates (and searching for missing) (Part 4)](http://community.idera.com/powershell/powertips/b/tips/posts/finding-installed-updates-and-searching-for-missing-part-4)
