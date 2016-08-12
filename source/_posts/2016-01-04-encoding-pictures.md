layout: post
date: 2016-01-04 12:00:00
title: "PowerShell 技能连载 - ___"
description: PowerTip of the Day - Encoding Pictures
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
If your script needs resources such as icons or pictures, you do not have to ship these resources separately. They can be Base64-encoded and added to your script as plain text.

This example illustrates how to convert a JPG picture into a Base64-encoded string:

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
    

The function Convert-JPG2Base64 accepts the path to a JPG picture and returns the Base64-encoded picture. In this example, we take the first JPG wallpaper found in your Windows folder. Make sure your Windows folder contains wallpaper pictures, or change the path to a JPG picture of your choice.

The resulting text can be embedded into a script. However, the resulting Base64-text can be pretty large, depending on the size and quality of the picture.

Tomorrow, we show how to load the picture from the Base64-string into memory, and use the picture in your own WPF window.

<!--more-->
本文国际来源：[Encoding Pictures](http://powershell.com/cs/blogs/tips/archive/2016/01/04/encoding-pictures.aspx)
