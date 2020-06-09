---
layout: post
date: 2020-06-05 00:00:00
title: "PowerShell 技能连载 - 添加参数自动完成（第 1 部分）"
description: PowerTip of the Day - Adding Argument Completion (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 函数参数中添加参数完成功能可以极大地提高函数的可用性。一种常见的方法是将 `[ValidateSet()]` 属性添加到您的参数中：

```powershell
function Get-Country
{
  param
  (
    # suggest country names
    [ValidateSet('USA','Germany','Norway','Sweden','Austria','YouNameIt')]
    [string]
    $Name
  )

  # return parameter
  $PSBoundParameters
}
```

现在，当用户使用 `Get-Country` 命令并传入 `-Name` 参数时，该函数现在会在用户按下 TAB 时建议国家/地区名称。像 PowerShell ISE 或 Visual Studio Code 这样的复杂PowerShell 编辑器甚至会自动打开 IntelliSense 菜单，或者在您按 CTRL + SPACE 显示所有的值。

但是，`[ValidateSet()]` 属性将用户限制为列出的值。无法输入其他值。如果只想为 `-ComputerName` 参数建议最常用的服务器名称，则将用户限制为仅使用这些服务器名称。这不是一个好主意。

从 PowerShell 7 开始，有一个名为 `[ArgumentCompletions()]` 的新属性，该属性几乎与 `[ValidateSet()]` 相似，但它跳过了验证部分。它提供相同的参数补全，但不限制用户输入：

```powershell
function Get-Country
{
  param
  (
    # suggest country names
    [ArgumentCompletions('USA','Germany','Norway','Sweden','Austria','YouNameIt')]
    [string]
    $Name
  )

  # return parameter
  $PSBoundParameters
}
```

此版本的 `Get-Country` 提供国家名称建议，但是如果您愿意，您仍然可以输入其他任何国家名称。

重要提示：由于 PowerShell 中的错误，参数自动完成对于定义具体功能的脚本窗格不起作用。而在 PowerShell 控制台和任何其他编辑器脚本窗格中，参数自动完成可以正常工作。

Windows PowerShell 中缺少新的 `[ArgumentCompletions()]` 属性，因此在使用它时，您的函数不再与 Windows PowerShell 兼容。我们将在即将到来的提示中解决此问题。

<!--本文国际来源：[Adding Argument Completion (Part 1)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-argument-completion-part-1)-->

