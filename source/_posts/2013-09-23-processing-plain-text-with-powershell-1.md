layout: post
title: "用 PowerShell 处理纯文本 - 1"
date: 2013-09-23 00:00:00
description: Processing Plain Text with PowerShell - 1
categories:
- powershell
- text
tags:
- powershell
- learning
- skill
- script
- regex
---
原始文本："data1":111,"data2":22,"data3":3,"data4":4444444,"data5":589
要求：转换成对象

方法一，采用字符串运算及 `ConvertFrom-StringData` 命令：

	$rawTxt='"data1":111,"data2":22,"data3":3,"data4":4444444'
	$rawTxt -split ',' | ForEach-Object {
	   $temp= $_ -split ':'
	   "{0}={1}" -f $temp[0].Substring(1,$temp[0].Length-2),$temp[1]
	} | ConvertFrom-StringData

方法二，采用正则表达式，使用.NET的方法：

	$rawTxt = '"data1":111,"data2":22,"data3":3,"data4":4444444,"data5":589'
	$regex = [regex] '"(?<name>\w*)":(?<value>\d*),?'
	$match = $regex.Match($rawTxt)
	while ($match.Success) {
		[PSCustomObject]@{
		    Name = $match.Groups['name'].Value
		    Value = $match.Groups['value'].Value
		}
		$match = $match.NextMatch()
	} 

方法三，采用正则表达式，使用 `Select-String` Cmdlet：

	Select-String -InputObject $rawTxt -Pattern $regex -AllMatches | % {
	    $_.Matches
	} | % {
	   [PSCustomObject]@{
	        Name = $_.Groups['name'].Value
	        Value = $_.Groups['value'].Value
	    }
	}

三者的执行结果都是这样：

	Name          Value
	----          -----
	data1         111
	data2         22
	data3         3
	data4         4444444
	data5         589

原命题参见：[PowerShell 文本处理实例(三)] [1]

[1]: http://www.pstips.net/processing-text-3.html "PowerShell 文本处理实例(三)"
