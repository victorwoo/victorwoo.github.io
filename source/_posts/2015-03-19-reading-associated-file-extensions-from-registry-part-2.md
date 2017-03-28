layout: post
date: 2015-03-19 11:00:00
title: "PowerShell 技能连载 - 从注册表中读取文件扩展名关联（第二部分）"
description: PowerTip of the Day - Reading Associated File Extensions from Registry (Part 2)
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

在前一个技能里您已学到了如何用单行代码读取多个注册表键。在第二部分中，请试试这段单行代码：

    $lookup = Get-ItemProperty Registry::HKCR\.[a-f]?? | 
      Select-Object -Property PSChildName, '(default)', ContentType, PerceivedType |
      Group-Object -Property PSChildName -AsHashTable -AsString

这段代码读取注册表 _HKCR_ 中所有以点开头，接下来是三个字母，并且第一个字母必须是 a-f 的键——它的作用是读取所有以 a-f 开头，并且必须是 3 个字符的文件扩展名。

另外，结果通过管道输出到 `Group-Object`，并且“`PSChildName`”属性被用作哈希表的键名。

`PSChildName` 总是返回注册表的键名，在这个例子中代表的是文件的扩展名。

当您运行这行代码时，您可以查询任何已注册的文件扩展名：

    PS> $lookup.'.avi'
    
    PSChildName         (default)           ContentType         PerceivedType      
    -----------         ---------           -----------         -------------      
    .avi                WMP11.AssocFile.AVI                     video              
    
    
    
    PS> $lookup.'.fon'
    
    PSChildName         (default)           ContentType         PerceivedType      
    -----------         ---------           -----------         -------------      
    .fon                fonfile                                                    

请注意这行代码限制了只包括 a-f 开头、三个字母的扩展名。要获取所有的文件扩展名，请使用这个路径：

    Registry::HKCR\.*

<!--more-->
本文国际来源：[Reading Associated File Extensions from Registry (Part 2)](http://community.idera.com/powershell/powertips/b/tips/posts/reading-associated-file-extensions-from-registry-part-2)
