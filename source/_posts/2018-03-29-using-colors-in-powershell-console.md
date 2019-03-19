---
layout: post
date: 2018-03-29 00:00:00
title: "PowerShell 技能连载 - 在 PowerShell 控制台中使用颜色"
description: PowerTip of the Day - Using Colors in PowerShell Console
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

要对一段文字着色，您在任何 PowerShell 版本中都可以使用 `Write-Host` 和它的 `-ForegroundColor` 和 `-BackgroundColor` 属性：

```powershell
foreach($color1 in (0..15))
{
    foreach($color2 in (0..15))
    {
        Write-Host -ForegroundColor ([ConsoleColor]$color1) -BackgroundColor ([ConsoleColor]$color2) -Object "X" -NoNewline
    }

    Write-Host
}



XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXX
```

通过使用 VT 转义序列，您可以使用范围更广的颜色。可以将前景色和背景色设为任意的 RGB 颜色。每个通道可以有 8 比特 (0-255)：

```powershell
# Red/Green/Blue foreground
$r = 0
$g = 20
$b = 255

# Red/Green/Blue background
$rback = 255
$gback = 100
$bback = 0

$esc = [char]27

# compose escape sequence
"$esc[38;2;$r;$g;$b;48;2;$rback;$gback;${bback}mCOLORFUL TEXT$esc[0m"
```

以下代码创建所有可能的颜色，并且将它们显示在由 256 个字符组成的一行上，并且每一行叠加在前一行之上，这样可以获得一个渐变发光的效果：

```powershell
$esc = [char]27
$setCursorTop = "$esc[0;0H"

foreach($rback in (0..255))
{
    foreach($gback in (0..255))
    {
        foreach($bback in (0..255))
        {

            foreach($r in (0..255))
            {
                foreach($g in (0..255))
                {
                    [System.Text.StringBuilder]$line = ""
                    foreach($b in (0..255))
                    {
                        $null = $line.Append("$esc[38;2;$r;$g;$b;48;2;$rback;$gback;${bback}mX$esc[0m")
                    }

                    $text = $line.ToString()
                    Write-Host "$setCursorTop$Text"
                }

                Write-Host
            }
        }
    }
}
```

<!--本文国际来源：[Using Colors in PowerShell Console](http://community.idera.com/powershell/powertips/b/tips/posts/using-colors-in-powershell-console)-->
