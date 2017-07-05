---
layout: post
date: 2017-07-04 00:00:00
title: "PowerShell 技能连载 - 读取注册表键值（临时解决办法）"
description: PowerTip of the Day - Reading Registry Values (Workaround)
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
在前一个技能中我们演示了 `Get-ItemProperty` 无法读取数据错误的注册表键值：

```powershell
PS> $key =  "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group  Policy\History\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}\0"


PS>  Get-ItemProperty -Path $key
Get-ItemProperty :  Specified cast is not valid.
At line:1 char:1
+ Get-ItemProperty  -Path $key
+  ~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:)  [Get-ItemProperty], InvalidCastException
    + FullyQualifiedErrorId :  System.InvalidCastException,Microsoft.PowerShell.Commands.GetItemPropertyComma
    nd


PS>
```

有一个变通办法，您可以使用 `Get-Item` 代替，来存取注册表键，这将使用它的 .NET 成员来读取所有值：

```powershell
$key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}\0"

$key = Get-Item -Path $key

$hash = @{}
foreach ($prop in $key.Property)
{
    $hash.$prop = $key.GetValue($prop)
}

$hash
```

结果看起来如下：

```powershell
Name                           Value
----                           -----
Extensions                     [{35378EAC-683F-11D2-A89A-00C04FBBCFA2}{0F6B957E-509E-11D1-A7CC-0000F87571E3}]
Link                           Local
Options                        0
GPOLink                        1
Version                        65537
GPOName                        Guidelines of the local group
lParam                         0
DSPath                         LocalGPO
FileSysPath                    C:\WINDOWS\System32\GroupPolicy\Machine
DisplayName                    Guidelines of the local group
```

<!--more-->
本文国际来源：[Reading Registry Values (Workaround)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-registry-values-workaround)
