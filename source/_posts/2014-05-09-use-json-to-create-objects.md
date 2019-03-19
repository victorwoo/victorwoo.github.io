---
layout: post
title: "PowerShell 技能连载 - 用 JSON 来创建对象"
date: 2014-05-09 00:00:00
description: PowerTip of the Day - Use JSON to Create Objects
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
JSON 用来描述对象的，类似 XML，但是 JSON 更简单得多.JSON 支持嵌套的对象属性，所以您可以从各种数据源中获取信息，然后将它们合并成一个自定义对象。

让我们来看看效果。以下代码创建一个清单条目，包含了电脑的许多详细信息：

    $json = @"
    {
        "ServerName": "$env:ComputerName",
        "UserName": "$env:UserName",
        "BIOS": {
             "Manufacturer" : "$((Get-WmiObject -Class Win32_BIOS).Manufacturer)",
             "Version" : "$((Get-WmiObject -Class Win32_BIOS).Version)",
             "Serial" : "$((Get-WmiObject -Class Win32_BIOS).SerialNumber)"
             },
        "OS" : "$([Environment]::OSVersion.VersionString)"
     }
    "@

    $info = ConvertFrom-Json -InputObject $json

    $info.ServerName
    $info.BIOS.Version
    $info.OS

您接下来可以操作结果对象——获取信息，或增加、更新详细信息。

如果您对对象做了改动，可以用 `ConvertTo-Json` 将它序列化为 JSON 对象格式：

![](/img/2014-05-09-use-json-to-create-objects-001.png)

<!--本文国际来源：[Use JSON to Create Objects](http://community.idera.com/powershell/powertips/b/tips/posts/use-json-to-create-objects)-->
