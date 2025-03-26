---
layout: post
date: 2022-07-15 00:00:00
title: "PowerShell 技能连载 - 在选中的代码中运行 $PSScriptRoot"
description: PowerTip of the Day - Running $PSScriptRoot in Selected Code
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
PowerShell 代码中的最大陷阱之一是自动变量 `$PSScriptRoot`，它始终代表当前脚本所在的文件夹的路径。但是，这要求 (a)当前脚本实际上已经保存到文件中，并且 (b)您正在执行整个文件，即通过按 `F5` 执行。

当您仅使用 `F8` 执行选中的代码时，即使您选择了整个代码，`$PSScriptRoot` 也为空，因此也会导致您选择的代码执行错误。

但是，在 PowerShell ISE 中，添加一些代码就能很容易地实现在选中的代码中启用 `$PSScriptRoot`。这是您需要运行的代码：

```powershell
function Invoke-Selection
{
    try
    {
        # get the selected text:
        $selectedText = $psise.CurrentFile.Editor.SelectedText
        # if no text was selected...
        if ($selectedText.Length -eq 0) {
            # ...select the line the caret is in and get this line instead:
            $psise.CurrentFile.Editor.SelectCaretLine()
            $selectedText = $psise.CurrentFile.Editor.SelectedText
        }

        # try and parse the code
        $sb = [ScriptBlock]::Create($selectedText)

        # get the missing variable content from the underlying file:
        $currentFile = $psise.CurrentFile.FullPath
        $currentFolder = Split-Path -Path $currentFile

        # append the selected code with these automatic variables, and set them:
        $runcode = @"
        `$PSCommandPath = '$currentFile'
        `$PSScriptRoot = '$currentFolder'
        $selectedText
"@
        # turn text into script block...
        $scriptblock = [ScriptBlock]::Create($runcode)
        # ...and execute it without private scope:
        . $scriptblock

    }
    catch
    {
        throw $_.Exception
    }

}
$null = $psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add('ExecuteSelection', {. Invoke-Selection}, 'SHIFT+F8')
```

该代码向 ISE 添加了一个新命令，可以通过按 `CTRL`+`F8` 来调用该命令。现在，假设您选择了一段代码，这段代码包含了 `$PSScriptRoot`，您若希望运行它，只需按 `CTRL`+`F8` 而不是 `F8`，它将正常执行。

该快捷键调用了 `Invoke-Selection` 函数。此函数将接受当前选择的文本，添加缺少的自动变量 `$PSScriptRoot` 和 `$PSCommandPath` 到代码中，并根据当前脚本的当前文件路径来定义这些变量。然后执行脚本块。

这样，您现在可以调试并演示任何选中的代码，即使它包含自动变量。只需确保您将脚本保存在某个地方，以便 PowerShell 知道您的代码所在的位置。

<!--本文国际来源：[Running $PSScriptRoot in Selected Code](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/running-psscriptroot-in-selected-code)-->

