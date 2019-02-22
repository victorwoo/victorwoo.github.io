---
layout: post
date: 2017-07-13 00:00:00
title: "PowerShell 技能连载 - 清除所有用户变量"
description: PowerTip of the Day - Clearing All User Variables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用类似这样的方法来查找内置的 PowerShell 变量：

```powershell
$ps = [PowerShell]::Create()
$null = $ps.AddScript('$null=$host;Get-Variable')
$ps.Invoke()
$ps.Runspace.Close()
$ps.Dispose()
```

现在我们来做相反的事情，创建一个函数来查找仅由你创建的用户变量：

```powershell
function Get-UserVariable ($Name = '*')
{
    # these variables may exist in certain environments (like ISE, or after use of foreach)
    $special = 'ps','psise','psunsupportedconsoleapplications', 'foreach', 'profile'

    $ps = [PowerShell]::Create()
    $null = $ps.AddScript('$null=$host;Get-Variable')
    $reserved = $ps.Invoke() |
    Select-Object -ExpandProperty Name
    $ps.Runspace.Close()
    $ps.Dispose()
    Get-Variable -Scope Global |
    Where-Object Name -like $Name |
    Where-Object { $reserved -notcontains $_.Name } |
    Where-Object { $special -notcontains $_.Name } |
    Where-Object Name
}
```

现在可以很容易查找所有由您（或您的脚本）创建并仍然停留在内存中的变量：

```powershell
PS> Get-UserVariable

Name                           Value
----                           -----
hash                           {Extensions, Link, Options, GPOLink...}
prop                           lParam
reserved                       {$, ?, ^, args...}
result                         {System.Management.Automation.PSVariable, System.Management.Automation.Ques...
varCount                       43



PS> Get-UserVariable -Name pr*

Name                           Value
----                           -----
prop                           lParam
```

如果要清理您的运行空间，您可以用一行代码清除所有变量：

```powershell
PS> Get-UserVariable

Name                           Value
----                           -----
hash                           {Extensions, Link, Options, GPOLink...}
key                            HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\H...
prop                           lParam
reserved                       {$, ?, ^, args...}
result                         {System.Management.Automation.PSVariable, System.Management.Automation.Ques...
varCount                       43



PS> Get-UserVariable | Remove-Variable

PS> Get-UserVariable

PS>
```

<!--本文国际来源：[Clearing All User Variables](http://community.idera.com/powershell/powertips/b/tips/posts/clearing-all-user-variables)-->
