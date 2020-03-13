---
layout: post
date: 2020-02-26 00:00:00
title: "PowerShell 技能连载 - 带颜色的控制台硬拷贝"
description: PowerTip of the Day - Creating Colorful Console Hardcopies
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想硬拷贝 PowerShell 控制台的内容，则可以复制和选择文本，但这会弄乱颜色和格式。

更好的方法是读取控制台屏幕缓冲区，并编写 HTML 文档。然后可以将这些 HTML 文档复制并粘贴到 Word 和其他目标中，并保持格式和颜色。

以下代码当然还不是完美的，但说明了采用的方法：

```powershell
function Get-ConsoleBufferAsHtml{
  $html = [Text.StringBuilder]''  $null = $html.Append("<pre style='MARGIN: 0in 10pt 0in;      line-height:normal';      font-family:Consolas;  font-size:10pt; >")
  $bufferWidth = $host.UI.RawUI.BufferSize.Width  $bufferHeight = $host.UI.RawUI.CursorPosition.Y  $rec = [Management.Automation.Host.Rectangle]::new(
    0,0,($bufferWidth - 1),$bufferHeight  )
  $buffer = $host.ui.rawui.GetBufferContents($rec)

  for($i = 0; $i -lt $bufferHeight; $i++)
  {
    $span = [Text.StringBuilder]''    $foreColor = $buffer[$i, 0].Foregroundcolor    $backColor = $buffer[$i, 0].Backgroundcolor    for($j = 0; $j -lt $bufferWidth; $j++)
    {
      $cell = $buffer[$i,$j]
      if (($cell.ForegroundColor -ne $foreColor) -or ($cell.BackgroundColor -ne $backColor))
      {
        $null = $html.Append("<span style='color:$foreColor;background:$backColor'>$($span)</span>"        )
        $span = [Text.StringBuilder]''        $foreColor = $cell.Foregroundcolor        $backColor = $cell.Backgroundcolor      }
      $null = $span.Append([Web.HttpUtility]::HtmlEncode($cell.Character))

    }
    $null = $html.Append("<span style='color:$foreColor;background:$backColor'>$($span)</span><br/>"    )
  }

  $null = $html.Append("</pre>")
  $html.ToString()
}
```

请注意，此功能需要一个真实的控制台窗口，因此在 PowerShell ISE 中将无法使用。当您运行上述代码时，它将为您提供一个名为 `Get-ConsoleBufferAsHtml` 的新命令。

要将当前控制台内容硬拷贝到 HTML 文件，请运行以下命令：

```powershell
PS>  Get-ConsoleBufferAsHtml | Set-Content $env:temp\test.html
```

要在关联的浏览器中打开生成的 HTML，请运行以下命令：

```powershell
PS>  Invoke-Item $env:temp\test.html
```
<!--本文国际来源：[Creating Colorful Console Hardcopies](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/creating-colorful-console-hardcopies)-->

