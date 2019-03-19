---
layout: post
date: 2018-03-30 00:00:00
title: "PowerShell 技能连载 - 对 Cmdlet 的输出着色"
description: PowerTip of the Day - Colorizing Cmdlet Output
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
从 PowerShell 5.1 开始，PowerShell 控制台支持 VT 转义序列，它可以用于对控制台文本定位和格式化。请注意它只对控制台有效，而对 PowerShell ISE 无效。另外还请注意您需要 Windows 10 或者类似 ConEmu 等模拟器。

当您向 `Select-Object` 命令传入一个哈希表时，该哈希表能够产生“计算的”列。它提供了两块信息：名字（列名）和表达式（一个生成列内容的脚本块）。

这对为 cmdlet 的输出着色十分有用。只需要创建一个添加彩色的 VT 转义序列的表达式即可。在以下例子中，一些文件类型被着色：

```powershell
$ColoredName = @{
    Name = "Name"
    Expression =
    {
        switch ($_.Extension)
        {
            '.exe'    { $color = "255;0;0"; break }
            '.log' { $color = '0;255;0'; break }
            '.ini'    { $color = "0;0;255"; break }
            default    { $color = "255;255;255" }
        }
        $esc = [char]27
        "$esc[38;2;${color}m$($_.Name)${esc}[0m"
    }
}

Get-ChildItem $env:windir |
    Select-Object -Property Mode, LastWriteTime, Length, $ColoredName
```

<!--本文国际来源：[Colorizing Cmdlet Output](http://community.idera.com/powershell/powertips/b/tips/posts/colorizing-cmdlet-output)-->
