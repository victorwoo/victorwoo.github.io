---
layout: post
date: 2020-03-13 00:00:00
title: "PowerShell 技能连载 - 动态参数完成（第 3 部分）"
description: PowerTip of the Day - Dynamic Argument Completion (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
根据我们过去讨论的技巧，让我们编写一个有用的最终代码，以列出所有可以启动的程序：

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

        })]
        [string]
        $Path
    )

    Start-Process -FilePath $Path
}
```

当您运行上述代码然后调用 `Start-Software` 时，请按 CTRL + SPACE，以使用简称来查看可用应用程序的完整列表。选择一个后，将自动完成绝对路径。路径包含空格时将自动加上单引号。

请注意，您可以先输入一些字符，例如 exc，然后按 CTRL + SPACE。这将预过滤 IntelliSense 列表。

另请注意：根据计算机上安装的软件和驱动器的速度，此示例中的完成代码可能需要一些时间才能执行。如果 IntelliSense 菜单超时，请按 CTRL + SPACE 再试一次。

<!--本文国际来源：[Dynamic Argument Completion (Part 3)](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/dynamic-argument-completion-part-3)-->

