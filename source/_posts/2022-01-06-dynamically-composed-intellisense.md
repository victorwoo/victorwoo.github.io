---
layout: post
date: 2022-01-06 00:00:00
title: "PowerShell 技能连载 - 动态生成 IntelliSense."
description: PowerTip of the Day - Dynamically Composed IntelliSense
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在设计 PowerShell 函数时，您可以通过添加智能参数完成 IntelliSense 来提高可用性。

要编写某个参数的 IntelliSense 自动完成，您可以使用动态生成 IntelliSense 列表的 PowerShell 代码来填充函数的每个参数。当然，您使用的代码应该能快速计算出结果，IntelliSense 才不会超时。

如果需要将方法（命令）添加到对象，请通过 `Add-Member` 添加它们：

```powershell
function Get-MyLocalUser
{
  #Content
  param
  (
    [String]
    [Parameter(Mandatory)]
    [ArgumentCompleter({
          # receive information about current state:
          param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

          Get-LocalUser |
            ForEach-Object {
              $name = $_.Name
              $desc = $_.Sid    # showing SID as QuickTip
              [System.Management.Automation.CompletionResult]::new($name, $name, "ParameterValue", $desc)
            }
      })]
      $UserName
  )

  "You chose $UserName"

}
```

运行代码后，在交互式控制台中键入：

```powershell
PS> Get-MyLocalUser -UserName
```

在 `-UnerName` 后按下空格，IntelliSense 介入并显示所有本地用户名。当您选择一个 IntelliSense 项目时，QuickTip 会显示用户的 SID。

此智能参数完成在 `[ArgumentCompleter()]` 属性中定义。 它内部的代码生成了 `CompletionResult` 对象，每个对象对应一个 IntelliSense 列表项。

<!--本文国际来源：[Dynamically Composed IntelliSense](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamically-composed-intellisense)-->

