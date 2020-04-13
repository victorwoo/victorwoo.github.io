---
layout: post
date: 2020-03-19 00:00:00
title: "PowerShell 技能连载 - PowerShell 技能连载 - 动态参数完成（第 5 部分）"
description: PowerTip of the Day - Dynamic Argument Completion (Part 5)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前面的技能中，我们研究了完成应用程序路径的复杂的完成代码。收集完成值可能需要一些时间，并且有可能使 IntelliSense 超时。对于不太可能更改的完成值，最好先计算一次，然后再使用缓存的值。

通过这种方式，安装自动完成器可能会占用一两秒时间，但是在那之后就可以享受快速的 IntelliSense：

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


}

# calculate the completion values once, and reuse the values later
# store results in a script-global variable
$script:applicationCompleter = & {
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

# instead of complex code, simply return the cached results when needed
$code = { $script:applicationCompleter }

# tie the completer code to all applicable parameters of own or foreign commands
Register-ArgumentCompleter -CommandName Start-Software -ParameterName Path -ScriptBlock $code
Register-ArgumentCompleter -CommandName Start-Process -ParameterName FilePath -ScriptBlock $code
```

当您运行上面的代码然后使用 `Start-Software` 或 `Start-Process` 命令时，您将获得高度响应的 IntelliSense。与内置的完成功能相反，您需要手动按 CTRL + SPACE。

<!--本文国际来源：[Dynamic Argument Completion (Part 5)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamic-argument-completion-part-5)-->
