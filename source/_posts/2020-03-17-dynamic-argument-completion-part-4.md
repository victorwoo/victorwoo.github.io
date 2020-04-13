---
layout: post
date: 2020-03-17 00:00:00
title: "PowerShell 技能连载 - 动态参数完成（第 4 部分）"
description: PowerTip of the Day - Dynamic Argument Completion (Part 4)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在上一个技能中，我们解释了如何使用 `[ArgumentCompleter]` 为参数添加功能强大的参数完成器。但是有一些限制：

* 当完成代码变得复杂时，您的代码将变得难以阅读
* 您不能将参数完成添加到现有命令。`[ArgumentCompleter]` 属性仅适用于您自己的函数。

但是，实际上，该属性只是将参数完成程序代码添加到 PowerShell 的两种方法之一。您也可以使用 `Register-ArgumentCompleter` 并将代码添加到现有命令中。

让我们首先看一下先前技巧中的示例：

```powershell
function Start-Software {
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({


# get registered applications from registry
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

[System.Collections.Generic.List[string]]$list =
    Get-ItemProperty -Path $key |
    Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore

# add applications found by Get-Command
[System.Collections.Generic.List[string]]$commands =
    Get-Command -CommandType Application |
    Select-Object -ExpandProperty Source
$list.AddRange($commands)

# add descriptions and compose completion result entries
$list |
    # remove empty paths
    Where-Object { $_ } |
    # remove quotes and turn to lower case
    ForEach-Object { $_.Replace('"','').Trim().ToLower() } |
    # remove duplicate paths
    Sort-Object -Unique |
    ForEach-Object {
        # skip files that do not exist
        if ( (Test-Path -Path $_))
        {
            # get file details
            $file = Get-Item -Path $_
            # quote path if it has spaces
            $path = $_
            if ($path -like '* *') { $path = "'$path'" }
            # make sure tooltip is not null
            $tooltip = [string]$file.VersionInfo.FileDescription
            if ([string]::IsNullOrEmpty($tooltip)) { $tooltip = $file.Name }
            # compose completion result
            [Management.Automation.CompletionResult]::new(
                # complete path
                $path,
                # show friendly text in IntelliSense menu
                ('{0} ({1})' -f $tooltip, $file.Name),
                # use file icon
                'ProviderItem',
                # show file description
                $tooltip
                )
        }
    }

        })]
        [string]
        $Path
    )

    Start-Process -FilePath $Path
}
```

函数 `Start-Software` 使用 `[ArgumentCompleter]` 属性定义了参数完成器，并且当使用 `Start-Software` 时，能获得 `-Path` 参数丰富的完成信息。

以下是一种替代方法，可以将完成程序代码单独发送到 PowerShell，而不使用属性。而是使用 `Register-ArgumentCompleter` 将完成程序代码绑定到任何命令的任何参数：

```powershell
# define a function without argument completer
function Start-Software {
    param(
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    Start-Process -FilePath $Path
}

# define the code used for completing application paths
$code = {

# get registered applications from registry
$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*"

[System.Collections.Generic.List[string]]$list =
    Get-ItemProperty -Path $key |
    Select-Object -ExpandProperty '(Default)' -ErrorAction Ignore

# add applications found by Get-Command
[System.Collections.Generic.List[string]]$commands =
    Get-Command -CommandType Application |
    Select-Object -ExpandProperty Source
$list.AddRange($commands)

# add descriptions and compose completionresult entries
$list |
    # remove empty paths
    Where-Object { $_ } |
    # remove quotes and turn to lower case
    ForEach-Object { $_.Replace('"','').Trim().ToLower() } |
    # remove duplicate paths
    Sort-Object -Unique |
    ForEach-Object {
        # skip files that do not exist
        if ( (Test-Path -Path $_))
        {
            # get file details
            $file = Get-Item -Path $_
            # quote path if it has spaces
            $path = $_
            if ($path -like '* *') { $path = "'$path'" }
            # make sure tooltip is not null
            $tooltip = [string]$file.VersionInfo.FileDescription
            if ([string]::IsNullOrEmpty($tooltip)) { $tooltip = $file.Name }
            # compose completion result
            [Management.Automation.CompletionResult]::new(
                # complete path
                $path,
                # show friendly text in IntelliSense menu
                ('{0} ({1})' -f $tooltip, $file.Name),
                # use file icon
                'ProviderItem',
                # show file description
                $tooltip
                )
        }
    }
}

# tie the completer code to all applicable parameters of own or foreign commands
Register-ArgumentCompleter -CommandName Start-Software -ParameterName Path -ScriptBlock $code
Register-ArgumentCompleter -CommandName Start-Process -ParameterName FilePath -ScriptBlock $code
```

现在，您自己的 `Start-Software` 函数的 `-Path` 参数和内置 cmdlet `Start-Process` 功能参数完成的 -FilePath 参数。完成代码可以重复利用。

注意：根据计算机上安装的软件和驱动器的速度，此示例中的完成代码可能需要一些时间才能执行。如果 IntelliSense 菜单超时，请按 CTRL + SPACE 再试一次。

<!--本文国际来源：[Dynamic Argument Completion (Part 4)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamic-argument-completion-part-4)-->
