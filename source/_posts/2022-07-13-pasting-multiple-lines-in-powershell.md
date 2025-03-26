---
layout: post
date: 2022-07-13 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 中粘贴多行"
description: PowerTip of the Day - Pasting Multiple Lines in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
当您复制多行 PowerShell 代码并将其粘贴到 Shell 窗口中时，结果通常不是您所期望的。PowerShell 开始执行第一行，不会以整块的方式执行粘贴的代码。试着复制下面的代码，然后将其粘贴到 PowerShell 控制台窗口中来查看默认行为：

```powershell
"Starting!"
$a = Read-Host -Prompt 'Enter something'
"Entered: $a"
"Completed"
```

粘贴块的每一行都是单独执行的，在每个输出行之前，可以看到命令提示符。

尽管此默认行为也可正常执行，但是如果您希望确保整个代码块作为一个整体执行，则将其嵌入大括号中，并用 "`.`" 执行此脚本块。尝试复制这段代码：

```powershell
. {
    "Starting!"
    $a = Read-Host -Prompt 'Enter something'
    "Entered: $a"
    "Completed"
}
```

当您粘贴此代码时，它会像从脚本文件中存储并加载它一样作为一个整体执行。

<!--本文国际来源：[Pasting Multiple Lines in PowerShell](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/pasting-multiple-lines-in-powershell)-->

