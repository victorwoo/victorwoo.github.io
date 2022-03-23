---
layout: post
date: 2022-03-03 00:00:00
title: "PowerShell 技能连载 - 自定义基于控制台的对话框"
description: PowerTip of the Day - Custom Console-Based Dialog
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
使用第三方对话框并不总是一个好的选择。复用内置的 PowerShell 对话框会更有意思。这是一个名为 `Show-ConsoleDialog` 的函数，您可以用各种选项灵活地构造这样的对话框。

该对话框在纯控制台环境（如 PowerShell 7 或 VSCode）和 PowerShell ISE（作为自定义对话框弹出）中同样显示良好。

```powershell
function Show-ConsoleDialog
{
  param
  (
    [Parameter(Mandatory)]
    [string]
    $Message,

    [string]
    $Title = 'PowerShell',

    # do not use choices with duplicate first letter
    # submit any number of choices you want to offer
    [string[]]
    $Choice = ('Yes', 'No')



  )


  # turn choices into ChoiceDescription objects
  $choices = foreach ($_ in $choice)
  {
    [System.Management.Automation.Host.ChoiceDescription]::new("&$_", $_)
  }

  # translate the user choice into the name of the chosen choice
  $choices[$host.ui.PromptForChoice($title, $message, $choices, 1)].Label.Substring(1)
}
```

你可以像这样使用它：

```powershell
$result = Show-ConsoleDialog -Message 'Restarting Server?' -Title 'Will restart server for maintenance' -Choice 'Yes','No','Later','Never','Always'

switch ($result)
{
    'Yes'        { 'restarting' }
    'No'         { 'doing nothing' }
    'Later'      { 'ok, later' }
    'Never'      { 'will not ask again' }
    'Always'     { 'restarting without notice now and ever' }
}
```

返回值为用户选择的名称。例如，使用 `switch` 语句来响应用户的选择。

另请注意，每个选项的第一个字母会变成键盘快捷键，因此不要使用具有重复首字母的选项。

<!--本文国际来源：[Custom Console-Based Dialog](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/custom-console-based-dialog)-->

