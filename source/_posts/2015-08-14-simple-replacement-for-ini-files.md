layout: post
date: 2015-08-14 11:00:00
title: "PowerShell 技能连载 - 简单的 INI 文件替代"
description: PowerTip of the Day - Simple Replacement for INI Files
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
如果您想将设置保存在您的脚本之外并将它们保存在一个独立的配置文件中，那么您可以使用各种数据格式。

INI 文件的并地支持并不充分，所以您得人工处理它们。JSON 和 XML 文件有处理器支持，但是文字内容太复杂，不容易被人类阅读。

If your config data can be expressed as key-value pairs like below, then we have an alternative:
如果您的配置数据是类似这样的键值对，那么我们可以有别的选择：

```text
Name = 'Tom'
ID = 12
Path = 'C:'
```

将键值对保存为一个纯文本文件，然后使用这段代码来读取该文件：

    $hashtable = @{}
    $path = 'z:\yourfilename.config'
    
    $payload = Get-Content -Path $path |
    Where-Object { $_ -like '*=*' } |
    ForEach-Object {
        $infos = $_ -split '='
        $key = $infos[0].Trim()
        $value = $infos[1].Trim()
        $hashtable.$key = $value
    }

结果是一个哈希表，您可以用这种方式轻松地读取各项的值：

    $hashtable.Name
    $hashtable.ID
    $hashtable.Path

<!--more-->
本文国际来源：[Simple Replacement for INI Files](http://community.idera.com/powershell/powertips/b/tips/posts/simple-replacement-for-ini-files)
