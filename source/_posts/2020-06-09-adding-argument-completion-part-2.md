---
layout: post
date: 2020-06-09 00:00:00
title: "PowerShell 技能连载 - 添加参数自动完成（第 2 部分）"
description: PowerTip of the Day - Adding Argument Completion (Part 2)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们讨论了已添加到 PowerShell 7 新的 `[ArgumentCompletions()]` 属性，以及如何使用它向函数参数添加复杂的参数完成功能。

不幸的是，该属性在 Windows PowerShell 中不可用，因此使用此属性，您的代码将不再与 Windows PowerShell 兼容。

当然，您还可以将属性添加到 Windows PowerShell。当您在Windows PowerShell中运行以下代码时， `[ArgumentCompletions()]` 属性将变为可用。PowerShell 7 代码仍然保持兼容，现在您也可以在Windows PowerShell中开始使用此属性：

```powershell
# are we running in Windows PowerShell?
if ($PSVersionTable.PSEdition -ne 'Core')
{
  # add the attribute [ArgumentCompletions()]
  $code = @'
using System;
using System.Collections.Generic;
using System.Management.Automation;

    public class ArgumentCompletionsAttribute : ArgumentCompleterAttribute
    {

        private static ScriptBlock _createScriptBlock(params string[] completions)
        {
            string text = "\"" + string.Join("\",\"", completions) + "\"";
            string code = "param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams);@(" + text + ") -like \"*$WordToComplete*\" | Foreach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }";
            return ScriptBlock.Create(code);
        }

        public ArgumentCompletionsAttribute(params string[] completions) : base(_createScriptBlock(completions))
        {
        }
    }
'@

  $null = Add-Type -TypeDefinition $code *>&1
}
```

如您所见，代码仅在 Windows PowerShell 中运行时才添加新属性。在PowerShell 7中，该属性已内置。

现在，无论您打算在 Windows PowerShell 还是Windows 7 中使用它，都可以在函数中使用复杂的参数完成。只需将上面的代码添加到代码中，以确保存在该属性。

这是使用属性并提供参数完成的函数的示例：

```powershell
function Get-Country
{
  param
  (
    # suggest country names:
    [ArgumentCompletions('USA','Germany','Norway','Sweden','Austria','YouNameIt')]
    [string]
    $Name
  )

  # return parameter
  $PSBoundParameters
}
```

当您在 PowerShell ISE（它是纯粹的 Windows PowerShell）中运行代码，然后在交互式控制台中使用 `Get-Country` 时，PowerShell ISE 会自动为 `-Name` 参数建议参数值（国家/地区名称）。

这里还有两件事要考虑：

* 由于 PowerShell 中存在长期的错误，这种类型的参数完成功能在定义实际功能的编辑器脚本窗格中不起作用。它始终可以在交互式控制台（这是最重要的用例）和任何其他脚本窗格中使用。
* 与 `[ValidateSet()]` 属性相反，新的 `[ArgumentCompletions()]` 属性并不将用户输入限制为列出的值。新属性仅提供您定义的建议，而不以任何方式限制用户输入。

有关此处使用的技术的更多详细信息，请访问 [https://powershell.one/powershell-internals/attributes/auto-completion](https://powershell.one/powershell-internals/attributes/auto-completion)。

<!--本文国际来源：[Adding Argument Completion (Part 2)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-argument-completion-part-2)-->

