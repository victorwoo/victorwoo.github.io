layout: post
date: 2016-02-08 12:00:00
title: "PowerShell 技能连载 - 统计一个 Word 文档中的页数"
description: PowerTip of the Day - Counting Pages in a Word Document
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
假设您有一系列 Word 文档，并且希望知道它们共有多少页。以下是一个函数，传入一个 Word 文件参数，便能得到它包含多少页：

    #requires -Version 1
    
    # adjust path to point to an existing Word file:
    $Path = "C:\...\SomeChapter.doc"
    $word = New-Object -ComObject Word.Application
    $word.Visible = $true
    $binding = 'System.Reflection.BindingFlags' -as [type]
    $doc = $word.Documents.Open($Path)
    $doc.Repaginate()
    $prop = $doc.BuiltInDocumentProperties(14)
    $pages = [System.__ComObject].invokemember('value',$binding::GetProperty,$null,$prop,$null)
    $doc.Close(0)
    $word.Quit()
    "$Path has $Pages pages."

如果这对您有用，可以将它改为一个函数，您就可以用 PowerShell 来统计多个 Word 文档共有多少页。

<!--more-->
本文国际来源：[Counting Pages in a Word Document](http://community.idera.com/powershell/powertips/b/tips/posts/counting-pages-in-a-word-document)
