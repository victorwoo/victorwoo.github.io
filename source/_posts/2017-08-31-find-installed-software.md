---
layout: post
date: 2017-08-31 00:00:00
title: "PowerShell 技能连载 - 查找安装的软件"
description: PowerTip of the Day - Find Installed Software
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
大多数已安装的文件将自己注册在 Windows 注册表中的四个位置。以下是一个名为 `Get-InstalledSoftware` 的快速 PowerShell 函数，它能够查询所有这些键名，然后输出找到的软件的信息。

```powershell
function Get-InstalledSoftware
{
    param
    (
        $DisplayName='*',

        $DisplayVersion='*',

        $UninstallString='*',

        $InstallDate='*'

    )

    # registry locations where installed software is logged
    $pathAllUser = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $pathCurrentUser = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $pathAllUser32 = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $pathCurrentUser32 = "Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"


    # get all values
    Get-ItemProperty -Path $pathAllUser, $pathCurrentUser, $pathAllUser32, $pathCurrentUser32 |
      # choose the values to use
      Select-Object -Property DisplayVersion, DisplayName, UninstallString, InstallDate |
      # skip all values w/o displayname
      Where-Object DisplayName -ne $null |
      # apply user filters submitted via parameter:
      Where-Object DisplayName -like $DisplayName |
      Where-Object DisplayVersion -like $DisplayVersion |
      Where-Object UninstallString -like $UninstallString |
      Where-Object InstallDate -like $InstallDate |

      # sort by displayname
      Sort-Object -Property DisplayName
}
```

这个函数也演示了如何不使用 PowerShell 驱动器而直接使用原生的注册表路径。方法是在路径前面添加 provider 的名称。在这个例子中是 `Registry::`。

这个函数将所有输出的列（属性）也暴露为参数，所以可以方便地过滤查询结果。以下例子演示了如何查找所有名字包含“Microsoft”的软件：

```
    PS C:\> Get-InstalledSoftware -DisplayName *Microsoft*

    DisplayVersion DisplayName
    -------------- -----------
                   Definition Update for Microsoft Office 2013 (KB3115404) 32-Bit...
    15.0.4569.1506 Microsoft Access MUI (English) 2013
    15.0.4569.1506 Microsoft Access Setup Metadata MUI (English) 2013
    15.0.4569.1506 Microsoft DCF MUI (English) 2013
    15.0.4569.1506 Microsoft Excel MUI (English) 2013
    15.0.4569.1506 Microsoft Groove MUI (English) 2013
    (...)
```

<!--more-->
本文国际来源：[Find Installed Software](http://community.idera.com/powershell/powertips/b/tips/posts/find-installed-software)
