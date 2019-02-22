---
layout: post
date: 2017-11-16 00:00:00
title: "PowerShell 技能连载 - Getting File Extension"
description: PowerTip of the Day - Getting File Extension
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
By converting a path to a FileInfo object, you can easily determine the path parent folder or file extension. Have a look:

    ([IO.FileInfo]'c:\test\abc.ps1').Extension 
    
    ([IO.FileInfo]'c:\test\abc.ps1').DirectoryName

<!--本文国际来源：[Getting File Extension](http://community.idera.com/powershell/powertips/b/tips/posts/getting-file-extension)-->
