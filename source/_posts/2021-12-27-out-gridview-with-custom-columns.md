---
layout: post
date: 2021-12-27 00:00:00
title: "PowerShell 技能连载 - Out-GridView 自定义列"
description: PowerTip of the Day - Out-GridView with Custom Columns
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您使用 `-OutputMode` 或 `-PassThru` 参数时，`Out-GridView` 可以是一个通用对话框。执行此操作时，网格视图窗口会在其右下角显示其他按钮，以便您可以选择项目并将它们传递给其他 cmdlet。

此行代码可以帮助选择要停止的服务，例如：

```powershell
Get-Service | Where-Object CanStop | Out-GridView -Title 'Service to stop?' -OutputMode Single | Stop-Service -WhatIf
```

但是，`Out-GridView` 无法控制它显示的属性。在上面的示例中，用户实际上只需要查看服务名称以及可能的依赖服务。

当然，您可以使用 `Select-Object` 来选择要显示的属性。现在网格视图窗口将准确显示您要求的列，但由于您永久删除了所有其他属性并更改了对象类型，后续 cmdlet 可能会如你所想的不能正常工作：

```powershell
Get-Service | Where-Object CanStop | Select-Object -Property DisplayName, DependentServices | Out-GridView -Title 'Service to stop?' -OutputMode Single | Stop-Service -WhatIf
```

运行上面这行代码时，网格视图窗口现在看起来很棒，但 `Stop-Service` 将不再停止选择您选择的服务，因为 `Select-Object` 将对象类型从 `Service` 更改为自定义对象：

    Stop-Service : The specified wildcard character pattern is not valid: @{DisplayName=Windows Audio Endpoint Builder;
    DependentServices=System.ServiceProcess.ServiceController[]}

在上一个技能中，我们已经使用了一种隐藏的技术，您可以使用它来告诉 `Out-GridView` 它应该显示哪些列——无需删除任何属性或更改对象类型：

```powershell
# create object that tells PowerShell which column(s) should be visible:
# show "DisplayName", and "DependentServices"
[string[]]$visible = 'DisplayName', 'DependentServices'
$type = 'DefaultDisplayPropertySet'
[System.Management.Automation.PSMemberInfo[]]$info =
[System.Management.Automation.PSPropertySet]::new($type,$visible)


Get-Service |
    Where-Object CanStop |
    # add the secret object to each object that you pipe into Out-GridView:
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $info -PassThru |
    Out-GridView -Title 'Service to stop?' -OutputMode Single |
    Stop-Service -WhatIf
```

不幸的是，当您这样做时，您可能会遇到红色错误消息。某些 PowerShell 对象（例如 Service）已经使用了我们尝试添加的巧妙技巧，因此您无法覆盖 PSStandardMembers 属性。要解决此问题，只需通过 `Select-Object *` 运行它们来克隆对象：

```powershell
# create object that tells PowerShell which column(s) should be visible:
# show "DisplayName", and "DependentServices"
[string[]]$visible = 'DisplayName', 'DependentServices'
$type = 'DefaultDisplayPropertySet'
[System.Management.Automation.PSMemberInfo[]]$info =
[System.Management.Automation.PSPropertySet]::new($type,$visible)


Get-Service |
    Where-Object CanStop |
    # clone the objects so they now belong to you:
    Select-Object -Property * |
    # add the secret object to each object that you pipe into Out-GridView:
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $info -PassThru |
    Out-GridView -Title 'Service to stop?' -OutputMode Single |
    Stop-Service -WhatIf
```

现在一切都很神奇，`Out-GridView` 仅显示您选择的属性。尽管如此，`Stop-Process` 继续获得输出信息并停止您选择的服务（删除 `-WhatIf` 来真实地停止服务，请确保您有管理员权限进行此操作）。

虽然通过 `Select-Object` 运行对象确实会更改其对象类型，但大多数 cmdlet 仍会继续处理这些对象，因为它们仍包含所有属性。这是最后一个示例：即使 `Out-GridView` 仅显示您选择的属性，对象仍包含所有属性，包括隐藏在网格视图窗口中的属性：

```powershell
# create object that tells PowerShell which column(s) should be visible:
# show "Name", "Description" and "MainWindowTitle"
[string[]]$visible = 'Name', 'Description', 'MainWindowTitle'
$type = 'DefaultDisplayPropertySet'
[System.Management.Automation.PSMemberInfo[]]$info =
[System.Management.Automation.PSPropertySet]::new($type,$visible)


Get-Process |
    Where-Object MainWindowTitle |
    Sort-Object -Property Name |
    # clone the objects so they now belong to you:
    Select-Object -Property * |
    # add the secret object to each object that you pipe into Out-GridView:
    Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $info -PassThru |
    Out-GridView -Title 'Select a process' -OutputMode Single |
    # still all properties available:
    Select-Object -Property *
```

<!--本文国际来源：[Out-GridView with Custom Columns](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/out-gridview-with-custom-columns)-->

