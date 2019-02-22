---
layout: post
date: 2017-12-20 00:00:00
title: "PowerShell 技能连载 - 以 JSON 格式读取和保存选项"
description: PowerTip of the Day - Loading and Saving Options in JSON Format
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
如果您想在脚本中保存信息，您也许希望将数据保存成 JSON 格式的对象。以下是一个例子：

```powershell
# define options object
$options = [PSCustomObject]@{
    Color = 'Red'
    Height = 12
    Name = 'Weltner'
}

# play with options settings
$options.Color = 'Blue'

# save options to file
$Path = "c:\test\options.json"
$options | ConvertTo-Json | Set-Content -Path $Path

# load options from file
$options2 = Get-Content -Path $Path | ConvertTo-Json
```

请确保路径 "c:\test" 存在。脚本将创建一个包含指定数据的自定义对象，并将它以 JSON 的格式保存到磁盘。下一步，数据将在您需要的时候读取出来。例如在另外一个脚本中，或读取初始设置时。

<!--本文国际来源：[Loading and Saving Options in JSON Format](http://community.idera.com/powershell/powertips/b/tips/posts/loading-and-saving-options-in-json-format)-->
