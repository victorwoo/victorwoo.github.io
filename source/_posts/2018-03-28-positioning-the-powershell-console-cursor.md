---
layout: post
date: 2018-03-28 00:00:00
title: "PowerShell 技能连载 - PowerShell 控制台光标定位"
description: PowerTip of the Day - Positioning the PowerShell Console Cursor
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

VT 转义序列可以将控制台光标设置到控制台窗口的任意位置。例如，要将光标设置到左上角，请使用以下代码：

```powershell
$esc = [char]27
$setCursorTop = "$esc[0;0H"

Write-Host "${setCursorTop}This always appears in line 0 and column 0!"
```

当您运行这段代码时，文字总是定位在第 0 行 第 0 列。您可以使用这种技术来创建您自己的进度指示器——只需要记住：这一切只在控制台窗口中有效，在 PowerShell ISE 中无效。

```powershell
function Show-CustomProgress
{
    try
    {
        $esc = [char]27
    
        # let the caret move to column (horizontal) pos 12
        $column = 12
        $resetHorizontalPos = "$esc[${column}G"
        $gotoFirstColumn = "$esc[0G"
        
        $hideCursor = "$esc[?25l"
        $showCursor = "$esc[?25h"
        $resetAll = "$esc[0m" 

        # write the template text
        Write-Host "${hideCursor}Processing     %." -NoNewline

        1..100 | ForEach-Object {
            # insert the current percentage
            Write-Host "$resetHorizontalPos$_" -NoNewline
            Start-Sleep -Milliseconds 100
        }
    }
    finally
    {
        # reset display
        Write-Host "${gotoFirstColumn}Done.              $resetAll$showCursor"
    }
}
```

运行这段代码后，执行 `Show-CustomProgress` 命令，您将会见到一个不断增长的自定义进度指示器。控制台隐藏了闪烁的光标提示。当进度指示器结束时，或者当按下 `CTRL` + `C` 时，进度指示器将会隐藏，

<!--本文国际来源：[Positioning the PowerShell Console Cursor](http://community.idera.com/powershell/powertips/b/tips/posts/positioning-the-powershell-console-cursor)-->
