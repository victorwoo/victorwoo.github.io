---
layout: post
date: 2016-02-15 12:00:00
title: "PowerShell 技能连载 - 谁在监听？（第一部分）"
description: PowerTip of the Day - Who Is Listening? (Part 1)
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
一个过去十分好用的 `netstat.exe` 可以告诉您应用程序在监听哪些端口，不过结果是纯文本。PowerShell 可以用正则表达式将文本分割成 CSV 数据，`ConvertFrom-Csv` 可以将文本转换为真实的对象。

这是一个如何用 PowerShell 处理最基础数据的例子：

```powershell
#requires -Version 2
NETSTAT.EXE -anop tcp|
Select-Object -Skip  4|
ForEach-Object -Process {
  [regex]::replace($_.trim(),'\s+',' ')
}|
ConvertFrom-Csv -d ' ' -Header 'proto', 'src', 'dst', 'state', 'pid'|
Select-Object -Property src, state, @{
  name = 'process'
  expression = {
    (Get-Process -PipelineVariable $_.pid).name
  }
} |
Format-List
```

结果类似如下：

    src     : 0.0.0.0:135
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service,
              AdobeIPCBroker...}

    src     : 0.0.0.0:445
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service,
              AdobeIPCBroker...}

    src     : 0.0.0.0:5985
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service,
              AdobeIPCBroker...}

    src     : 0.0.0.0:7680
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service,
              AdobeIPCBroker...}

    src     : 0.0.0.0:7779
    state   : LISTEN
    process : {Adobe CEF Helper, Adobe CEF Helper, Adobe Desktop Service,
              AdobeIPCBroker...}

<!--本文国际来源：[Who Is Listening? (Part 1)](http://community.idera.com/powershell/powertips/b/tips/posts/who-is-listening-part-1)-->
