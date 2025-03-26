---
layout: post
date: 2023-07-11 08:00:05
title: "PowerShell 技能连载 - PowerShell 脚本未经确认无法运行"
description: "PowerTip of the Day - PowerShell Script Won’t Run Without Confirmation"
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当你在 Windows 中右键单击任何 PowerShell 脚本时，上下文菜单会出现“使用 PowerShell 运行”的选项。然而，当你选择这个选项时，可能会看到一个 PowerShell 控制台弹出，询问关于“执行策略”的奇怪问题。让我们明确一点：这与你个人的执行策略设置无关，这些通常控制着 PowerShell 脚本是否可以运行。

相反，上下文菜单命令运行它自己的代码。你可以在 Windows 注册表中查找：

```powershell
$path = 'HKEY_CLASSES_ROOT\SystemFileAssociations\.ps1\Shell\0\Command'
$name = ''
$value = Get-ItemProperty -Path "Registry::$path" -Name $name
$value.'(default)'
```

而这就是每当您调用它时上下文菜单命令运行的内容：

```powershell
if((Get-ExecutionPolicy ) -ne 'AllSigned')
{
Set-ExecutionPolicy -Scope Process Bypass -Force
}
& '%1'
```

所以基本上，除非你使用的是超严格的执行策略 "`AllSigned`"（几乎没有人这样做），否则执行策略会在临时情况下（仅限于此次调用）设置为 "`Bypass`"，以允许你运行右键单击的脚本文件。实际上，执行策略会稍微放宽一些，使得即使在未定义明确的执行策略的系统上也可以使用上下文菜单命令。

然而，`Set-ExecutionPolicy` 有向用户询问回复的倾向，在这里可能会导致烦人的提示框出现。用户真的不想每次使用此上下文菜单命令启动某个脚本时都被问到“确定吗？”

要解决这个问题，只需调整所述注册表键中的代码。在调用 `Set-ExecutionPolicy` 时添加 "`-Force`" 参数，这样该 cmdlet 就能够进行调整而无需提问。
<!--本文国际来源：[PowerShell Script Won’t Run Without Confirmation](https://blog.idera.com/database-tools/powershell/powertips/powershell-script-wont-run-without-confirmation/)-->

