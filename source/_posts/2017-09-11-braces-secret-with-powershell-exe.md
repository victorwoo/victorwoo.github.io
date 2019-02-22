---
layout: post
date: 2017-09-11 00:00:00
title: "PowerShell 技能连载 - PowerShell.exe 的“大括号秘密”"
description: "PowerTip of the Day - “Braces Secret” with PowerShell.exe"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当从 PowerShell 或 PowerShell Core 中调用 powershell.exe 时有一些小秘密：当您执行 `powershell.exe` 并通过 `-Command` 传递一些命令时，PowerShell 将运行这个命令并返回纯文本：

```powershell
$a = powershell -noprofile -Command Get-Service
$a[0].GetType().FullName
System.String
```

所以当您将代码放在大括号中执行时，PowerShell 会将强类型的结果序列化后返回：

```powershell
$a = powershell -noprofile -Command { Get-Service }
$a[0].GetType().FullName
System.Management.Automation.PSObject

$a[0] | Select-Object -Property *

Name                : AdobeARMservice
RequiredServices    : {}
CanPauseAndContinue : False
CanShutdown         : False
CanStop             : True
DisplayName         : Adobe Acrobat Update Service
DependentServices   : {}
MachineName         : .
ServiceName         : AdobeARMservice
ServicesDependedOn  : {}
Status              : Running
ServiceType         : Win32OwnProcess
StartType           : Automatic
Site                :
Container           :
```

<!--本文国际来源：[“Braces Secret” with PowerShell.exe](http://community.idera.com/powershell/powertips/b/tips/posts/braces-secret-with-powershell-exe)-->
