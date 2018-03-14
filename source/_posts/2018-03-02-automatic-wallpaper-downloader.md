---
layout: post
date: 2018-03-02 00:00:00
title: "PowerShell 技能连载 - 自动壁纸下载器"
description: PowerTip of the Day - Automatic Wallpaper Downloader
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
您对桌面壁纸感到厌倦了吗？PowerShell 可以帮您下载最新的壁纸！以下是一个函数：

```powershell
function Download-Wallpaper
{
    param
    (
        [string]
        [Parameter(Mandatory)]
        $Folder,

        [Parameter(ValueFromPipeline)]
        [Int]
        $Page=1
    )

    begin
    {
        $url = "http://wallpaperswide.com/page/$Page"
        $targetExists = Test-Path -Path $Folder
        if (!$targetExists) { $null = New-Item -Path $Folder -ItemType Directory }
    }
    process
    {
        $web = Invoke-WebRequest -Uri $url -UseBasicParsing

        $web.Images.src |
        ForEach-Object {

            $filename = $_.Split('/')[-1].Replace('t1.jpg','wallpaper-5120x3200.jpg')
            $source = "http://wallpaperswide.com/download/$filename"

            $TargetPath = Join-Path -Path $folder -ChildPath $filename

            Invoke-WebRequest -Uri $source -OutFile $TargetPath
        }
    }
    end
    {
        explorer $Folder
    }
}
```

以下是使用方法：

```powershell
PS> Download-Wallpaper -Folder c:\wallpapers
```

它将从一个公开的壁纸网站下载所有壁纸到本地文件夹，然后打开该文件夹。您所需要做的只是右键单击壁纸并且选择“设为桌面背景”。

默认情况下，`Download-Wallpaper` 从第一个页面下载壁纸。通过指定 `-Page` 参数，您可以从其它页面挖掘壁纸。请试试以下代码：

```powershell
PS> Download-Wallpaper -Folder c:\wallpapers
```

<!--more-->
本文国际来源：[Automatic Wallpaper Downloader](http://community.idera.com/powershell/powertips/b/tips/posts/automatic-wallpaper-downloader)
