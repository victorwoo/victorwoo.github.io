layout: post
date: 2017-02-14 00:00:00
title: "PowerShell 技能连载 - 检查 Execution Policy"
description: PowerTip of the Day - Checking Execution Policy
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- translation
---
execution policy 决定了 PowerShell 能执行哪类脚本。您需要将 execution policy 设置成 `Undefined`、`Restricted`，或 `Default` 之外的值，来允许脚本执行。

对于没有经验的用户，推荐使用 "`RemoteSigned`"。它可以运行本地脚本，也可以运行位于您信任的网络域的文件服务器上的脚本。它不会运行从 internet 上下载的脚本，或从其它非信任的源获取的脚本，除非这些脚本包含合法的数字签名。

以下是查看和设置当前 execution policy 的方法。

```powershell
    PS C:\> Get-ExecutionPolicy
    Restricted

    PS C:\> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

    PS C:\> Get-ExecutionPolicy
    RemoteSigned

    PS C:\>
```

当您使用 "`CurrentUser`" 作用域，那么不需要管理员权限来更改这个设置。这是您个人的安全带，而不是公司级别的安全边界。这个设置将会保持住直到您改变它。

如果您需要确保确保可以无人值守地运行任何地方的脚本，您可能需要使用 "`Bypass`" 设置，而不是 "`RemoteSigned`"。"`Bypass`" 允许运行任意位置的脚本，而且不像 "`“Unrestricted”`" 那样会弹出确认对话框。

<!--more-->
本文国际来源：[Checking Execution Policy](http://community.idera.com/powershell/powertips/b/tips/posts/checking-execution-policy)
