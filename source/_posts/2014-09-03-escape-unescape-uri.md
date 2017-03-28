layout: post
title: 用 PowerShell 快速转义、反转义 URI
date: 2014-09-03 21:17:20
description: Escape Unescape URI with PowerShell
categories: powershell
tags:
- powershell
- geek
---
有 PowerShell 在手，进行 URI 转义、反转义这点小事就不需要找别的工具了。

    # 对 URI 进行转义
    [System.Uri]::EscapeUriString('http://www.baidu.com/s?ie=UTF-8&wd=中文')
    # http://www.baidu.com/s?ie=UTF-8&wd=%E4%B8%AD%E6%96%87
    
    # 对数据进行转义
    [System.Uri]::EscapeDataString('http://www.baidu.com/s?ie=UTF-8&wd=中文')
    # http%3A%2F%2Fwww.baidu.com%2Fs%3Fie%3DUTF-8%26wd%3D%E4%B8%AD%E6%96%87
    
    # 对 HEX 数据进行反转义
    [System.Uri]::UnescapeDataString('http://www.baidu.com/s?ie=UTF-8&wd=%E4%B8%AD%E6%96%87')
    # http://www.baidu.com/s?ie=UTF-8&wd=中文
