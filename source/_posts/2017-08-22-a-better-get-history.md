---
layout: post
date: 2017-08-22 00:00:00
title: "PowerShell 技能连载 - 增强版 Get-History 命令"
description: PowerTip of the Day - A better Get-History
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您在 PowerShell 中输入 `h` 命令，您可以看到在这个会话中输入的命令历史。受到 Pratek Singh 的启发 [Powershell Get-History+ – Geekeefy](https://geekeefy.wordpress.com/2017/06/20/powershell-get-history/)，以下是一个灵活的 `h+` 命令，它能够在网格界面窗口中显示历史纪录，并且支持选定历史记录。按住 `CTRL` 键可以选择多个项目。

Pratek 通过 `Invoke-Expression` 命令执行所有选中的项目。这可能有风险，并且它并不显示命令，所以您不知道执行了什么命令。所以在 `h+` 中，我们把选中的项目复制到剪贴板中。这样，您可以将内容粘贴到需要的地方：可以粘贴到文件中，或是将它们粘贴回 PowerShell 来执行。将它们粘贴回 PowerShell 中之后，您还有机会查看这些命令，然后按 `ENTER` 键执行这些命令。

```powershell
Function h+
{
    Get-History |
        Out-GridView -Title "Command History - press CTRL to select multiple - Selected commands copied to clipboard" -OutputMode Multiple |
        ForEach-Object -Begin { [Text.StringBuilder]$sb = ""} -Process { $null = $sb.AppendLine($_.CommandLine) } -End { $sb.ToString() | clip }
}
```

只需要将 h+ 函数加入您的配置文件脚本中（可以通过 `$profile` 找到路径）这样它随时可以拿来使用。

<!--本文国际来源：[A better Get-History](http://community.idera.com/powershell/powertips/b/tips/posts/a-better-get-history)-->
