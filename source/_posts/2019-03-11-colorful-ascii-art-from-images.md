---
layout: post
date: 2019-03-11 00:00:00
title: "PowerShell 技能连载 - 从图片中创建彩色 ASCII 艺术"
description: PowerTip of the Day - Colorful ASCII-Art from Images
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在之前的技能中我们介绍了如何读取任何图片或照片，并将它转换为一个黑白 ASCII 艺术。今天，我们将修改 `Convert-ImageToAsciiArt` 函数：它输入一个函数并将它转换为彩色的 ASCII 艺术！

像素的亮度值将被转换为合适的 ASCII 字符，并且像素的颜色值将应用到该字符。ASCII 艺术将写入 HTML 文件，因为 HTML 是表示彩色文字的最简单格式。

```powershell
function Convert-ImageToAsciiArt
{
  param(
    [Parameter(Mandatory)][String]
    $ImagePath,

    [Parameter(Mandatory)][String]
    $OutputHtmlPath,

    [ValidateRange(20,20000)]
    [int]$MaxWidth=80
  )

  ,

  # character height:width ratio
  [float]$ratio = 1.5

  # load drawing functionality
  Add-Type -AssemblyName System.Drawing

  # characters from dark to light
  $characters = &#39;$#H&@*+;:-,. &#39;.ToCharArray()
  $c = $characters.count

  # load image and get image size
  $image = [Drawing.Image]::FromFile($ImagePath)
  [int]$maxheight = $image.Height / ($image.Width / $maxwidth) / $ratio

  # paint image on a bitmap with the desired size
  $bitmap = new-object Drawing.Bitmap($image,$maxwidth,$maxheight)


  # use a string builder to store the characters
  [System.Text.StringBuilder]$sb = "<html><building style=&#39;font-family:""Consolas""&#39;>"


  # take each pixel line...
  for ([int]$y=0; $y -lt $bitmap.Height; $y++) {
    # take each pixel column...
    $null = $sb.Append("<nobr>")
    for ([int]$x=0; $x -lt $bitmap.Width; $x++) {
      # examine pixel
      $color = $bitmap.GetPixel($x,$y)
      $brightness = $color.GetBrightness()
      # choose the character that best matches the
      # pixel brightness
      [int]$offset = [Math]::Floor($brightness*$c)
      $ch = $characters[$offset]
      if (-not $ch) { $ch = $characters[-1] }
      $col = "#{0:x2}{1:x2}{2:x2}" -f $color.r, $color.g, $color.b
      if ($ch -eq &#39; &#39;) { $ch = " "}
      $null = $sb.Append( "<span style=""color:$col""; ""white-space: nowrap;"">$ch</span>")
    }
    # add a new line
    $null = $sb.AppendLine("</nobr><br/>")
  }

  # close html document
  $null = $sb.AppendLine("</building></html>")

  # clean up and return string
  $image.Dispose()

  Set-Content -Path $OutputHtmlPath -Value $sb.ToString() -Encoding UTF8
}
```

还有以下是如何将一张图片转换为一个漂亮的 ASCII 艺术，并在浏览器VS显示，甚至在彩色打印机中打印出来：

```powershell
$ImagePath = "C:\someInputPicture.jpg"
$OutPath = "$home\desktop\ASCIIArt.htm"

Convert-ImageToAsciiArt -ImagePath $ImagePath -OutputHtml $OutPath -MaxWidth 150
Invoke-Item -Path $OutPath
```

可以通过调整 `-MaxWidth` 来控制细节。如果增加了宽度，那么也必须调整字体大小并增加字符数。对于更小的字符，您可能需要调整这行：

```powershell
[System.Text.StringBuilder]$sb = "<html><building style=&#39;font-family:""Consolas""&#39;>"
```

例如将它改为这行：

```powershell
[System.Text.StringBuilder]$sb = "<html><building style=&#39;font-family:""Consolas"";font-size:4px&#39;>"
```

<!--本文国际来源：[Colorful ASCII-Art from Images](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/colorful-ascii-art-from-images)-->

