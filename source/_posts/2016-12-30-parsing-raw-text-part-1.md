---
layout: post
date: 2016-12-30 00:00:00
title: "PowerShell 技能连载 - 解析纯文本（第一部分）"
description: PowerTip of the Day - Parsing Raw Text (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有些时候，您可能希望从纯文本结果中提取一些有用的信息。一个简单的办法是使用 `Select-String` 命令。这个例子只提取包含“IPv4”的文本行：


```powershell
PS C:\> ipconfig | Select-String 'IPv4'

   IPv4 Address. . . . . . . . . . . : 192.168.2.112
```

如果您只对实际的 IP 地址感兴趣，您可以改进这个结果，用正则表达式来提取您感兴趣的部分：

```powershell
PS C:\> $data = ipconfig | select-string 'IPv4' 
PS C:\> [regex]::Matches($data,"\b(?:\d{1,3}\.){3}\d{1,3}\b") | Select-Object -ExpandProperty Value

192.168.2.112
```

`[Regex]::Matches()` 输入原始数据和正则表达式 pattern，后者描述了您感兴趣的部分。符合该 pattern 的内容可以在“Value”属性中找到。

<!--本文国际来源：[Parsing Raw Text (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/parsing-raw-text-part-1)-->
