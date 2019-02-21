---
layout: post
date: 2019-02-18 00:00:00
title: "PowerShell 技能连载 - 将文本转为图像"
description: PowerTip of the Day - Converting Text to Image
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
WPF (Windows Presentation Foundation) 不仅仅是创建 UI 的技术。您可以用它来创建任意类型的矢量图并将它保存为图形文件。

以下是一个简单的例子，输入任意的文字和字体，然后将它渲染为一个 PNG 文件：

```powershell
function Convert-TextToImage
{
  param
  (
    [String]
    [Parameter(Mandatory)]
    $Text,
    
    [String]
    $Font = 'Consolas',
    
    [ValidateRange(5,400)]
    [Int]
    $FontSize = 24,
    
    [System.Windows.Media.Brush]
    $Foreground = [System.Windows.Media.Brushes]::Black,
    
    [System.Windows.Media.Brush]
    $Background = [System.Windows.Media.Brushes]::White
  )
  
  $filename = "$env:temp\$(Get-Random).png"

  # take a simple XAML template with some text  
  $xaml = @"
<TextBlock
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">$Text</TextBlock>
"@

  Add-Type -AssemblyName PresentationFramework
  
  # turn it into a UIElement
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  
  # refine its properties
  $result.FontFamily = $Font
  $result.FontSize = $FontSize
  $result.Foreground = $Foreground
  $result.Background = $Background
  
  # render it in memory to the desired size
  $result.Measure([System.Windows.Size]::new([Double]::PositiveInfinity, [Double]::PositiveInfinity))
  $result.Arrange([System.Windows.Rect]::new($result.DesiredSize))
  $result.UpdateLayout()
  
  # write it to a bitmap and save it as PNG
  $render = [System.Windows.Media.Imaging.RenderTargetBitmap]::new($result.ActualWidth, $result.ActualHeight, 96, 96, [System.Windows.Media.PixelFormats]::Default)
  $render.Render($result)
  Start-Sleep -Seconds 1
  $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
  $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($render))
  $filestream = [System.IO.FileStream]::new($filename, [System.IO.FileMode]::Create)
  $encoder.Save($filestream)
  
  # clean up
  $reader.Close() 
  $reader.Dispose()
  
  $filestream.Close()
  $filestream.Dispose()
  
  # return the file name for the generated image
  $filename 
}
```

以下是使用方法：

```powershell
PS> $file = Convert-TextToImage -Text 'Red Alert!' -Font Stencil -FontSize 60 -Foreground Red -Background Gray

PS> Invoke-Item -Path $file
```

今日的知识点：

* 通过 XAML，一个基于 XML 的 UI 描述语言，您可以定义图像。
* PowerShell 可以使用 `[Windows.Markup.XAMLReader]` 类来快速地将任意合法的 XAML 转换为一个 `UIElement` 对象。
* `UIElement` 对象可以保存成图形文件，例如 PNG 图像，可以在窗口中显示，或者打印出来。在这个例子中，我们主要是将它保存为文件，然后我们用了一个非常简单的 XAML 定义。您现在可能会感到很好奇。通过 Google 搜索一下这个例子中的方法，您将会找到很多知识。

<!--more-->
本文国际来源：[Converting Text to Image](https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/converting-text-to-image)
