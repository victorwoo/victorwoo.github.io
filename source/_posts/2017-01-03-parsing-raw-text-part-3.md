---
layout: post
date: 2017-01-03 00:00:00
title: "PowerShell 技能连载 - 解析纯文本（第三部分）"
description: PowerTip of the Day - Parsing Raw Text (Part 3)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在前一个技能中我们演示了如何用 `Select-String` 在纯文本中查找指定的词。费了一些功夫通过指定的 pattern 来提取实际的值：

```powershell
PS C:\> $data = ipconfig | select-string 'IPv4'
PS C:\> [regex]::Matches($data,"\b(?:\d{1,3}\.){3}\d{1,3}\b") | Select-Object -ExpandProperty Value

192.168.2.112
```

不过这些功夫并不是必要的，因为 `Select-String` 已经在使用正则表达式来做匹配，然后返回匹配的对象。


```powershell
PS C:\> ipconfig |
  Select-String '\b(?:\d{1,3}\.){3}\d{1,3}\b' |
  Select-Object -Property *



    IgnoreCase : True
    LineNumber : 16
    Line       :    IPv4 Address. . . . . . . . . . . : 192.168.2.112
    Filename   : InputStream
    Path       : InputStream
    Pattern    : \b(?:\d{1,3}\.){3}\d{1,3}\b
    Context    :
    Matches    : {192.168.2.112}

    IgnoreCase : True
    LineNumber : 17
    Line       :    Subnet Mask . . . . . . . . . . . : 255.255.255.0
    Filename   : InputStream
    Path       : InputStream
    Pattern    : \b(?:\d{1,3}\.){3}\d{1,3}\b
    Context    :
    Matches    : {255.255.255.0}

    IgnoreCase : True
    LineNumber : 19
    Line       :                                        192.168.2.1
    Filename   : InputStream
    Path       : InputStream
    Pattern    : \b(?:\d{1,3}\.){3}\d{1,3}\b
    Context    :
    Matches    : {192.168.2.1}
```

所以您可以简单地使用 `Where-Object` 和类似 `-like` 的操作符来预过滤，识别出只包含感兴趣内容的行（例如只包含 "IPV4" 的行），然后将一个正则表达式 pattern 传给 `Select-String`，并计算最终结果：


```powershell
PS C:\> ipconfig |
  # do raw prefiltering and get only lines containing this word
  Where-Object { $_ -like '*IPv4*' } |
  # do RegEx filtering using a pattern for IPv4 addresses
  Select-String '\b(?:\d{1,3}\.){3}\d{1,3}\b' |
  # get the matching values
  Select-Object -ExpandProperty Matches |
  # get the value for each match
  Select-Object -ExpandProperty Value

192.168.2.112
```

<!--本文国际来源：[Parsing Raw Text (Part 3)](http://community.idera.com/powershell/powertips/b/tips/posts/parsing-raw-text-part-3)-->
