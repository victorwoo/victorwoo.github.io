---
layout: post
date: 2020-12-02 00:00:00
title: "PowerShell 技能连载 - 读取上次登录的用户和其他注册表值"
description: PowerTip of the Day - Reading Last Logged-On User and Other Registry Values
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 PowerShell 读取一些注册表值通常很容易：只需使用 `Get-ItemProperty`。此代码段读取 Windows 操作系统的才详细信息，例如：

```powershell
$Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

Get-ItemProperty -Path $Path |
Select-Object -Property ProductName, CurrentBuild, ReleaseId, UBR
```

结果看起来像这样：

    ProductName    CurrentBuild ReleaseId UBR
    -----------    ------------ --------- ---
    Windows 10 Pro 19042        2009      630

不幸的是，`Get-ItemProperty` 实际上得与 `Select-Object` 结合使用才理想，因为 cmdlet 总是会添加许多属性。如果您只想读取一个注册表值，即最后一个登录的用户，则始终需要将两者结合起来：

```powershell
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

Get-ItemProperty -Path $Path |
Select-Object -ExpandProperty LastLoggedOnUser
```

另外，您可以将 `Get-ItemProperty` 的结果存储在变量中，并使用点号访问各个注册表值：

```powershell
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

$values = Get-ItemProperty -Path $Path
$values.LastLoggedOnUser
```

如果此调用不能帮助您从其他用户帐户启动 Windows Terminal，那么在即将发布的技能中，我们将说明如何将应用程序转变为不再由 Windows 管理的便携式应用程序。取而代之的是，您可以用任何用户（包括高级帐户）运行它。敬请关注。

```powershell
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"

$key = Get-Item -Path $Path
$key.GetValue('LastLoggedOnUser')
```

<!--本文国际来源：[Reading Last Logged-On User and Other Registry Values](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/reading-last-logged-on-user-and-other-registry-values)-->

