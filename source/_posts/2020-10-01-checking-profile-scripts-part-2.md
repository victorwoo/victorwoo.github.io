---
layout: post
date: 2020-10-01 00:00:00
title: "PowerShell 技能连载 - PowerShell技能连载-检查配置文件脚本（第 2 部分）"
description: PowerTip of the Day - Checking Profile Scripts (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个脚本中，我们介绍了一一行代码，用于检查哪些配置文件脚本是存在的。但是，此解决方案仅只适用于单个宿主，因为每个宿主都使用自己的特定于宿主的配置文件路径。

这是一种更通用的方法：它列出了系统上存在的所有 PowerShell 宿主的所有配置文件路径。然后，您可以在安全性或健全性检查中检查以下文件：

```powershell
# calculate the parent paths that can contain profile scripts
$Paths = @{
    AllUser_WPS = $pshome
    CurrentUser_WPS = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "WindowsPowerShell"
    AllUser_PS = "$env:programfiles\PowerShell\*"
    CurrentUser_PS = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath "PowerShell"
}

# check all paths for PowerShell scripts ending on "profile.ps1"
$Paths.Keys | ForEach-Object {
    $key = $_
    $path = Join-Path -Path $paths[$key] -ChildPath '*profile.ps1'
    Get-ChildItem -Path $Path |
        ForEach-Object {
        # create a custom object with all relevant details for any
        # found profile script

        # name of PowerShell host is the prefix of profile file name
        if ($_.Name -like '*_*')
        {
            $hostname = $_.Name.Substring(0, $_.Name.Length-12)
        }
        else
        {
            $hostname = 'any'
        }
        [PSCustomObject]@{
            # scope and PowerShell version is found in the
            # name of the parent folder
            Scope = $key.Split('_')[0]
            PowerShell = $key.Split('_')[1]

            Host = $hostname
            Path = $_.FullName
        }
        }
}
```

结果报告了所有主机的现有 PowerShell 配置文件脚本，看起来可能与此类似：

    Scope       PowerShell Host                    Path
    -----       ---------- ----                    ----
    CurrentUser WPS        Microsoft.PowerShellISE C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\Microsoft.PowerShellISE_...
    CurrentUser WPS        any                     C:\Users\tobia\OneDrive\Dokumente\WindowsPowerShell\profile.ps1
    CurrentUser PS         Microsoft.VSCode        C:\Users\tobia\OneDrive\Dokumente\PowerShell\Microsoft.VSCode_profile.ps1

<!--本文国际来源：[Checking Profile Scripts (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/checking-profile-scripts-part-2)-->

