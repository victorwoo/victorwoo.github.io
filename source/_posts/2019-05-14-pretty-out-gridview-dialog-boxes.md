---
layout: post
date: 2019-05-14 00:00:00
title: "PowerShell 技能连载 - 美化 Out-GridView 对话框"
description: PowerTip of the Day - Pretty Out-GridView Dialog Boxes
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您用管道将对象输出到 `Out-GridView`，该 cmdlet 显示缺省的属性，所以当您用一个网格视图窗口当作选择框时，您可以控制用户可见的内容。以下代码将读取前 10 个 AD 用户输出到网格视图窗口，并且用户可以选择要返回的项。然而，网格视图窗口中显示的数据看起来很丑：

```powershell
Get-ADUser -ResultSetSize 10 -Filter * |
    Out-GridView -Title 'Select-User' -OutputMode Single |
    Select-Object -Property *
```

如果您没有使用 AD 或没有安装 RSAT 工具，以下是使用进程的类似的例子：

```powershell
Get-Process |
  Where-Object MainWindowTitle |
  Out-GridView -Title 'Which process do you want to kill?' -OutputMode Single |
  Stop-Process -WhatIf
```

如果您使用 `Select-Object` 来限制显示的属性，这将改变对象的类型，所以当您继续用管道将改变过的对象传给下一级 cmdlet，它们将无法处理返回的对象。

解决方法是保持对象类型不变，而是改变缺省属性。以下是 AD 用户对象的解决方案，在选择对话框中只显示 Name 和 SID：

```powershell
[string[]]$visible = 'Name', 'SID'
$type = 'DefaultDisplayPropertySet'
[Management.Automation.PSMemberInfo[]]$i =
New-Object System.Management.Automation.PSPropertySet($type,$visible)

Get-ADUser -LDAPFilter '(samaccountname=schul*)' |
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $i -Force -PassThru |
    Out-GridView -Title 'Select-User' -OutputMode Single |
    Select-Object -Property *
```

这是进程选择框的解决方案，显示进程的名称、公司、起始时间，和窗体标题：

```powershell
[string[]]$visible = 'Name', 'Company','StartTime','MainWindowTitle'
$type = 'DefaultDisplayPropertySet'
[Management.Automation.PSMemberInfo[]]$i =
New-Object System.Management.Automation.PSPropertySet($type,$visible)



Get-Process |
  Where-Object MainWindowTitle |
  Sort-Object -Property Name |
  # important: object clone required
  Select-Object -Property * |
  Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $i -Force -PassThru |
  Out-GridView -Title 'Which process do you want to kill?' -OutputMode Single |
  Stop-Process -WhatIf
```

结果发现，进程对象不接受新的 `DefaultDisplayPropertySet`，所以在这个例子中需要一个完整的克隆，这样您可以用 `Select-Object -Property *` 将对象输出到管道。由于这不会改变对象类型，所以所有原始属性都被保留下来，下游管道命令能继续起作用，因为管道绑定仍然有效。

<!--本文国际来源：[Pretty Out-GridView Dialog Boxes](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/pretty-out-gridview-dialog-boxes)-->

