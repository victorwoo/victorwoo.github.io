layout: post
date: 2015-01-01 12:00:00
title: "PowerShell 技能连载 - 处理隐藏文件"
description: PowerTip of the Day - Dealing with Hidden Files
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
_适用于 PowerShell 3.0 及更高版本_

当您使用 `Get-ChildItem` 来列出文件时，缺省情况下不包含隐藏文件。

要包含隐藏文件，请使用 `-Force` 参数：

    PS> Get-ChildItem -Path $home -Force

要只列出隐藏文件，请使用 `-Hidden` 参数。这个参数是在 PowerShell 3.0 引入的：

    PS> Get-ChildItem -Path $home -Hidden
    
    
        Directory: C:\Users\Tobias
    
    
    Mode                LastWriteTime     Length Name                                                                
    ----                -------------     ------ ----                                                                
    d--h-        08.01.2012     10:38            AppData                                                             
    d--hs        08.01.2012     10:38            Application Data                                                    
    d--hs        08.01.2012     10:38            Cookies                                                             
    d--hs        08.01.2012     10:38            Local Settings                                                      
    d--hs        08.01.2012     10:38            My Documents                                                        
    d--hs        08.01.2012     10:38            NetHood                                                             
    (...)

<!--more-->
本文国际来源：[Dealing with Hidden Files](http://community.idera.com/powershell/powertips/b/tips/posts/dealing-with-hidden-files)
