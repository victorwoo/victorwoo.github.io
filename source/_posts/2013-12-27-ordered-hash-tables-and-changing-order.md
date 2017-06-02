---
layout: post
title: "PowerShell 技能连载 - 有序哈希表以及更改顺序"
date: 2013-12-27 00:00:00
description: PowerTip of the Day - Ordered Hash Tables and Changing Order
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
有序哈希表是在 PowerShell 3.0 中增加的新特性，它在创建新对象的时候十分有用。和常规的哈希表不同，有序哈希表保存了您添加键时的顺序，您还可以控制这些键转化为对象属性时的顺序。以下是一个例子：

	$hashtable = [Ordered]@{}
	$hashtable.Name = 'Tobias'
	$hashtable.ID = 12
	$hashtable.Location = 'Germany'

	New-Object -TypeName PSObject -Property $hashtable

这段代码创建了一个对象，它的属性定义严格按照它们指定时的先后顺序排列。

那么如果您希望不在尾部，例如在列表的头部增加一个属性，要怎么做呢？

	$hashtable = [Ordered]@{}
	$hashtable.Name = 'Tobias'
	$hashtable.ID = 12
	$hashtable.Location = 'Germany'
	$hashtable.Insert(0, 'Position', 'CSA')
	
	New-Object -TypeName PSObject -Property $hashtable

<!--more-->
本文国际来源：[Ordered Hash Tables and Changing Order](http://community.idera.com/powershell/powertips/b/tips/posts/ordered-hash-tables-and-changing-order)
