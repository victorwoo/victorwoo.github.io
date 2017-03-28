layout: post
date: 2016-10-10 00:00:00
title: "PowerShell 技能连载 - 在 Active Directory 中查找操作系统版本"
description: PowerTip of the Day - Finding Operating System Versions in Active Directory
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
如果您安装了带有 "ActiveDirectory" PowerShell 模块的 Microsoft RSAT 工具，以下是一个快速获取您环境中操作系统清单的快速方法：

```powershell
#requires -Module ActiveDirectory

Get-ADComputer -Filter * -Properties OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion  |
  Select-Object -Property Name, OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion
```

这将获得所有计算机的信息。您可以将搜索范围限制在指定的计算机名和 AD 位置中。以下命令将搜索范围限制在 $root AD 范围内，以及只包含名字以 "Serv" 开头的计算机中：

```powershell
#requires -Module ActiveDirectory

$root = 'OU=North,OU=Clients,DC=yourcompany,DC=com'

Get-ADComputer -Filter { Name -like 'Serv*' } -Properties OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion <#-ResultSetSize 10#> -SearchBase $root -SearchScope Subtree |
  Select-Object -Property Name, OperatingSystem, OperatingSystemServicePack, OperatingSystemVersion
```

<!--more-->
本文国际来源：[Finding Operating System Versions in Active Directory](http://community.idera.com/powershell/powertips/b/tips/posts/finding-operating-system-versions-in-active-directory)
