---
layout: post
date: 2016-01-04 12:00:00
title: "PowerShell 技能连载 - 对图片编码"
description: PowerTip of the Day - Encoding Pictures
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您的脚本需要图标或图片等资源，您不需要另外发布这些资源。它们可以用 Base64 编码并且以纯文本的方式加到您的脚本中。

这个例子演示了如何将一个 JPG 图片转换为 Base64 编码的字符串：

```powershell
function Convert-JPG2Base64 
 {
     param
     (
         [Parameter(Mandatory=$true)]
         [String]
         $Path
     )

    $format = [System.Drawing.Imaging.ImageFormat]::Jpeg

    $image = [System.Drawing.Image]::FromFile($Path)
    $stream = New-Object -TypeName System.IO.MemoryStream
    $image.Save($stream, $format)
    $bytes = [Byte[]]($stream.ToArray())
    [System.Convert]::ToBase64String($bytes, 'InsertLineBreaks')
}

# find a random picture
$picture = Get-ChildItem $env:windir\Web\Wallpaper *.jpg -Recurse |
   Select-Object -First 1

$pictureString = Convert-JPG2Base64 -Path $picture.FullName

$pictureString
```

`Convert-JPG2Base64` 函数接受一个 JPG 图片路径作为参数并且返回 Base64 编码后的图片。在这个例子中，我们使用 Windows 文件夹中的第一个 JPG 墙纸。请确保您的 Windows 文件夹中包含图片，或者把 JPG 图片的文件夹改为您想要的文件夹。

返回的文本可以嵌入一段脚本中。而且，返回的 Base64 文本可能会非常大，由图片的尺寸和质量决定。

明天，我们将演示如何将 Base64 编码后的图片加载到内存中，并在自己的 WPF 窗口中显示。

<!--本文国际来源：[Encoding Pictures](http://community.idera.com/powershell/powertips/b/tips/posts/encoding-pictures)-->
