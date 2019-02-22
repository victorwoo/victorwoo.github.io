---
layout: post
date: 2018-11-07 00:00:00
title: "PowerShell 技能连载 - 添加额外的安全防护"
description: PowerTip of the Day - Adding Extra Safety Net
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您正在编写 PowerShell 函数，并且知道某个函数可能会造成很多危险结果，那么有一个简单的方法可以增加一层额外的安全防护。以下是了个函数，一个没有安全防护，而另一个有安全防护：

```powershell
function NoSafety
{
    param
    (
        [Parameter(Mandatory)]
        $Something
    )
    "HARM DONE with $Something!"
}

function Safety
{
    # step 1: add -WhatIf and -Confirm, and mark as harmful
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param
    (
        [Parameter(Mandatory)]
        $Something
    )

    # step 2: abort function when confirmation was rejected
    if (!$PSCmdlet.ShouldProcess($env:computername, "doing something harmful"))
    {
        Write-Warning "Aborted!"
        return
    }

    "HARM DONE with $Something!"
}
```

当您运行 "`NoSafety`"，直接运行完毕。而当您运行 "`Safety`"，用户会得到一个确认提示，只有确认了该提示，函数才能继续执行。

要实现这个有两个步骤。第一，`[CmdletBinding(...)]` 语句增加了 `WhatIf` 和 `-Confirm` 参数，而 `ConfirmImpact="High"` 将函数标记为有潜在危险的。

第二，在函数代码中的第一件事情是调用 `$PSCmdlet.ShouldProcess`，在其中你可以定义确认信息。如果这个调用返回 `$false`，那么代码中的 `-not` 操作符 (`!`) 将抛出结果，而该函数立即返回。

用户仍然可以通过显式关闭确认的方式，不需确认运行该函数：

```powershell
PS> Safety -Something test -Confirm:$false
HARM DONE with test!
```

或者，通过设置 `$ConfirmPreference` 为 "`None`"，直接将本 PowerShell 会话中的所有的自动确认对话框关闭：

```powershell
PS> $ConfirmPreference = "None"

PS> Safety -Something test
HARM DONE with test!
```

<!--本文国际来源：[Adding Extra Safety Net](http://community.idera.com/database-tools/powershell/powertips/b/tips/posts/adding-extra-safety-net)-->
