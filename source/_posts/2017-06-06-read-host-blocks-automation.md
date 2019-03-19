---
layout: post
date: 2017-06-06 00:00:00
title: "PowerShell 技能连载 - Read-Host 阻塞自动化操作"
description: PowerTip of the Day - Read-Host Blocks Automation
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用 Read-Host 向用户提示输入信息可能会造成问题，因为它影响了脚本的自动化运行。一个更好的方法是将 `Read-Host` 包装在 `param()` 代码块中。通过这种方式，该信息可以通过无人值守操作的参数传入，也可以通过交互式提示传入：

```powershell
param
(
    $Name = $(Read-Host -Prompt 'Enter your name'),
    $Id = $(Read-Host -Prompt 'Enter your ID')
)


"You are $Name and your ID is $Id"
```

当您运行以上脚本时，它像 `Read-Host` 一模一样地显示提示信息。您也可以通过参数执行该脚本：

```powershell
PS> C:\myscript.ps1 –Name test –Id 12
```

If you do not need custom prompting, you can go even simpler, and declare parameters as mandatory by adding [Parameter(Mandatory)] above each parameter variable.
如果您不需要自定义提示信息，您还可以更加简单，只需要在每个参数变量上加上 `[Parameter(Mandatory)]` 使它们变为必需参数。

<!--本文国际来源：[Read-Host Blocks Automation](http://community.idera.com/powershell/powertips/b/tips/posts/read-host-blocks-automation)-->
