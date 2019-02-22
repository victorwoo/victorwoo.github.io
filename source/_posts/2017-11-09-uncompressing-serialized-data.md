---
layout: post
date: 2017-11-09 00:00:00
title: "PowerShell 技能连载 - 解压序列化的数据"
description: PowerTip of the Day - Uncompressing Serialized Data
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中您学习到了如何使用 `Export-CliXml` 命令来序列化数据并且用 `Compress-Archive` 将巨大的 XML 文件压缩成远远小于原始文件的尺寸。

今天，我们进行相反的操作：假设获得一个包含 XML 序列化数据的 ZIP 文件，然后恢复序列化的对象。当然这假设您已基于昨天的技能创建了这样的文件。

```powershell
# path to existing ZIP file
$ZipPath = "$env:TEMP\data1.zip"

# by convention, XML file inside the ZIP file has the same name
$Path = [IO.Path]::ChangeExtension($ZipPath, ".xml")

# expand ZIP file
Expand-Archive -Path $ZipPath -DestinationPath $env:temp -Force

# deserialize objects
$objects = Import-Clixml -Path $Path

# remove XML file again
Remove-Item -Path $Path -Recurse -Force

$objects | Out-GridView
```

<!--本文国际来源：[Uncompressing Serialized Data](http://community.idera.com/powershell/powertips/b/tips/posts/uncompressing-serialized-data)-->
