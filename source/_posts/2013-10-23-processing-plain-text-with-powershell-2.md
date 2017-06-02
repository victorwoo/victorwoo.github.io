---
layout: post
title: "用 PowerShell 处理纯文本 - 2"
date: 2013-10-23 00:00:00
description: Processing Plain Text with PowerShell - 2
categories:
- powershell
- text
tags:
- powershell
- learning
- skill
- script
---
应朋友要求，帮忙解决一例 PowerShell 问题：
> 有一个 CSV 文件，其中有一个 *Photo* 字段存的是 BASE64 编码的字符串，这个字符串包含换行符。在 `Import-Csv` 的时候，*Photo* 字段不会作为一个整体值，而是会变成每行一个。文件的内容是这样的：

	StaffNum,LogonName,ObjName,Title,Office,Department,Photo
	03138,wangjunhao,王俊豪,流程优化主管,宜山路,运营平台中心/项目部,/9j/4AAQSkZJRgABAgAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a
	HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIy
	...
	PyoooGSr0qRCdtFFMBy9qkFFFJCYo60w85oopgNzjoBTto9KKKQj/9k=

为了解决这个 case，先归纳它的规律：

1. BASE64 字符串的字符集为 0..9、a..z、A..Z，以及/和=。
2. BASE64 字符串每一行不超过 76 个字符。
3. 如果某一行从第一个字符到最后一个字符，都符合上述 2 条规律，说明前一行并没有结束。应当把当前行拼接到前一行中。

根据以上规律编写 PowerShell 代码：

	$fileName = 'AllUsers.csv'
	
	$currentLine = ''
	gc $fileName | % -process {
	        if ($_ -cmatch '^[a-zA-Z0-9/+=]{1,76}$') {
	            # 如果符合 BASE64 特征，说明上一行未结束。
	            $currentLine += $_
	        } else {
	            # 如果不符合 BASE64 特征，说明上一行是完整的。
	            Write-Output $currentLine
	            $currentLine = $_
	        }
	    } -end {
	        $currentLine
	    } | 
	ConvertFrom-Csv

完整的 .CSV 及 .PS1 文件请在[这里下载](/download/2013-10-23-processing-plain-text-with-powershell-2.zip)。
