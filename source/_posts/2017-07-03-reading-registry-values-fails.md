---
layout: post
date: 2017-07-03 00:00:00
title: "PowerShell 技能连载 - 读取注册表键值失败"
description: PowerTip of the Day - Reading Registry Values Fails
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
有些时候，读取注册表键值可能会失败，提示奇怪的错误信息：

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

当发生这种情况时，用 regedit.exe 检查注册表发现一个或多个键值已破坏。在我们的例子中，"lParam" 的值似乎在所有的 Windows 机器中都是错误的。Regedit.exe 报告“(invalid ... value)”。

在这个例子中，`Get-ItemProperty` 指令并不会读出任何值。您无法也排除该值：

```powershell
PS>  Get-ItemProperty -Path $key -Include * -Exclude lParam
Get-ItemProperty :  Specified cast is not valid.
At line:1 char:1
+ Get-ItemProperty  -Path $key -Include * -Exclude lParam
+  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:)  [Get-ItemProperty], InvalidCastException
    + FullyQualifiedErrorId :  System.InvalidCastException,Microsoft.PowerShell.Commands.GetItemPropertyCommand


PS>
```

可以采取的措施是只读取合法的键值：

```powershell
PS> Get-ItemProperty -Path $key -Name DSPath


DSPath       : LocalGPO
PSPath       : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersi
                on\Group Policy\History\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}\0
PSParentPath : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersi
                on\Group Policy\History\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}
PSChildName  : 0
PSProvider   : Microsoft.PowerShell.Core\Registry


PS>
```

<!--more-->
本文国际来源：[Reading Registry Values Fails](http://community.idera.com/powershell/powertips/b/tips/posts/reading-registry-values-fails)
