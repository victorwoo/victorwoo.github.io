---
layout: post
title: "PowerShell 技能连载 - 通过前缀对文件夹分组"
date: 2013-12-06 00:00:00
description: PowerTip of the Day - Getting Folders by Prefix
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
您知道吗？`Group-Object` 可以方便地以自定义的规则来对元素分组。以下通过简单的一行代码实现根据前三个字母对文件夹分组：

	Get-ChildItem -Path C:\Windows -Directory |
	   Group-Object -Property { $_.Name.PadRight(3).Substring(0,3)}

稍微做一些额外的改动，您可以以这三个首字母做为键，创建一个哈希表：

	$lookup = Get-ChildItem -Path $env:windir -Directory  |
	   Group-Object -Property { $_.Name.PadRight(3).Substring(0,3).ToUpper()} -AsHashTable -AsString
	
	$lookup.Keys

现在我们可以很容易地取得其中的文件夹，比如说我们要取以“SYS”开头的文件夹：

	PS C:\Windows\System32> $lookup.SYS
	
	
	    目录: C:\Windows
	
	
	Mode                LastWriteTime     Length Name                                                                                
	----                -------------     ------ ----                                                                                
	d----         2013/9/24     21:50            System                                                                              
	d-r--         2013/12/8     13:40            System32                                                                            
	d----         2013/8/22     23:36            SystemResources                                                                     
	d----         2013/12/5     11:29            SysWOW64  

这有什么实用价值呢？有些公司使用文件夹前缀作为业务单元。用上这个技术之后，我们可以很容易地把所有的业务单元文件夹“收拢”起来——您可以秒杀地计算它们的存储容量并且创建一个自动化的报表。

<!--本文国际来源：[Getting Folders by Prefix](http://community.idera.com/powershell/powertips/b/tips/posts/getting-folders-by-prefix)-->
