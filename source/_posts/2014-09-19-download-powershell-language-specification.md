---
layout: post
date: 2014-09-19 11:00:00
title: "PowerShell 技能连载 - 下载 PowerShell 语言规范"
description: PowerTip of the Day - Download PowerShell Language Specification
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
_适用于 PowerShell 所有版本_

在 PowerShell 中，从 Internet 中下载文件十分方便。以下这段代码能够自动将 PowerShell 语言规范——包含 PowerShell 精华和内核知识的很棒的 Word 文档——下载到您的机器上。

    $link = 'http://download.microsoft.com/download/3/2/6/326DF7A1-EE5B-491B-9130-F9AA9C23C29A/PowerShell%202%200%20Language%20Specification.docx'
    
    $outfile = "$env:temp\languageref.docx"
    
    Invoke-WebRequest -Uri $link -OutFile $outfile
    
    Invoke-Item -Path $outfile

<!--more-->
本文国际来源：[Download PowerShell Language Specification](http://community.idera.com/powershell/powertips/b/tips/posts/download-powershell-language-specification)
