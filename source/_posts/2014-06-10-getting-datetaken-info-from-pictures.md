layout: post
title: "PowerShell 技能连载 - 从照片中读取拍摄日期"
date: 2014-06-10 00:00:00
description: PowerTip of the Day - Getting DateTaken Info from Pictures
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
如果您想重新整理您的照片库，以下这段代码能帮您从照片文件中读取拍摄日期信息。

这个例子使用了一个系统函数来查找“我的照片”的路径，然后递归搜索它的子文件夹。输出的结果通过管道传递给 `Get-DataTaken`，该函数返回照片的文件名、文件夹名，以及照片的拍摄时间。

    function Get-DateTaken
    {
      param 
      (
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [String]
        $Path
      )
      
      begin
      {
        $shell = New-Object -COMObject Shell.Application
      }
      
      process
      {
      $returnvalue = 1 | Select-Object -Property Name, DateTaken, Folder
        $returnvalue.Name = Split-Path $path -Leaf
        $returnvalue.Folder = Split-Path $path
        $shellfolder = $shell.Namespace($returnvalue.Folder)
        $shellfile = $shellfolder.ParseName($returnvalue.Name)
        $returnvalue.DateTaken = $shellfolder.GetDetailsOf($shellfile, 12)
    
        $returnvalue
      }
    }
    
    $picturePath = [System.Environment]::GetFolderPath('MyPictures')
    Get-ChildItem -Path $picturePath -Recurse -ErrorAction SilentlyContinue | 
      Get-DateTaken

<!--more-->
本文国际来源：[Getting DateTaken Info from Pictures](http://community.idera.com/powershell/powertips/b/tips/posts/getting-datetaken-info-from-pictures)
