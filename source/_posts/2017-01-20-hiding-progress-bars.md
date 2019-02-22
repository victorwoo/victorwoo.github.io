---
layout: post
date: 2017-01-20 00:00:00
title: "PowerShell 技能连载 - 隐藏进度条"
description: PowerTip of the Day - Hiding Progress Bars
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些 cmdlet 和脚本使用进度条来指示进度。如您在前一个技能中所学的，进度条可能会导致延迟，所以如果您如果不想指示进度，您可能会希望隐藏进度条。以下是实现方法：

以下代码从互联网下载一张图片。`Invoke-WebRequest` 处理耗时的操作并且在下载时显示一个进度条：

```powershell
#requires -Version 3.0


$path = "$home\Pictures\psconf15.jpg"
$url = 'http://www.powertheshell.com/wp-content/uploads/groupWPK2015.jpg'
Invoke-WebRequest -Uri $url -OutFile $path  

Invoke-Item -Path $path
```

如果您不想显示进度条，请使用 `$ProgressPreference` 变量，临时隐藏进度条。请注意代码是如何用大括号包裹起来，并且用 ”&“ 号执行的。通过这种方法，当代码执行完毕后，所有在大括号中改变的变量都会被忽略，所以您不需要将 `$ProgressPreference` 变量重置为原来的值。

```powershell
#requires -Version 3.0


& {
  $ProgressPreference = 'SilentlyContinue'

  $path = "$home\Pictures\psconf15.jpg"
  $url = 'http://www.powertheshell.com/wp-content/uploads/groupWPK2015.jpg'
  Invoke-WebRequest -Uri $url -OutFile $path 
}
Invoke-Item -Path $path
```

<!--本文国际来源：[Hiding Progress Bars](http://community.idera.com/powershell/powertips/b/tips/posts/hiding-progress-bars)-->
