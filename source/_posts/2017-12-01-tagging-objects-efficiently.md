---
layout: post
date: 2017-12-01 00:00:00
title: "PowerShell 技能连载 - 为对象高效添加标记"
description: PowerTip of the Day - Tagging Objects Efficiently
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
有时候您会见到用 `Select-Object` 向已有对象增加信息的脚本，类似以下代码：

```powershell
Get-Process | 
    Select-Object -Property *, Sender|
    ForEach-Object { 
        $_.Sender = $env:COMPUTERNAME
        $_
    }
```

这段代码可以工作，但是 `Select-Object` 创建了一个全新的对象拷贝，所以这种方法速度比较慢并且改变了对象的类型。因为这个原因，您会注意到 PowerrShell 不再像正常的那样以表格的方式输出。

`Add-Member` 是首选的增加额外信息到已有对象的 cmdlet，因为它不会拷贝对象并且不会改变对象类型。请比较输出结果：

```powershell
Get-Process |
    Add-Member -MemberType NoteProperty -Name Sender -Value $env:COMPUTERNAME -PassThru
```

对象类型没有改变，并且 PowerShell 继续使用进程查看缺省的输出布局。这是因为新的 "Sender" 属性初始是不可见的。不过它事实上存在：

```powershell
Get-Process |
    Add-Member -MemberType NoteProperty -Name Sender -Value $env:COMPUTERNAME -PassThru |
    Select-Object -Property Name, Id, Sender
```

<!--more-->
本文国际来源：[Tagging Objects Efficiently](http://community.idera.com/powershell/powertips/b/tips/posts/tagging-objects-efficiently)
