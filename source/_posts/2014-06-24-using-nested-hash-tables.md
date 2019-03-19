---
layout: post
title: "PowerShell 技能连载 - 使用嵌套的哈希表"
date: 2014-06-24 00:00:00
description: PowerTip of the Day - Using Nested Hash Tables
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
嵌套的哈希表是代替多维数组的好方法。它能以易于管理的方式存储数据集合。让我们看一个例子：

    $person = @{}
    $person.Name = 'Weltner'
    $person.Id = 12
    $person.Address = @{}
    $person.Address.Street = 'Canyon Rim'
    $person.Address.City = 'Folsom'
    $person.Address.Details = @{}
    $person.Address.Details.Story = 4
    $person.Address.Details.ScenicView = $false

这段代码定义了一个 person 变量。您可以这样查看 person 的内容：

    PS> $person
	Name                           Value
	----                           -----
	Name                           Weltner
	Id                             12
	Address                        {Street, Details, City}

您还可以这样方便地获取其中的一部分信息：

	PS> $person
	Name
	Weltner

	PS> $person.Address.City
	Folsom

	PS> $person.Address.Details.ScenicView
	False

<!--本文国际来源：[Using Nested Hash Tables](http://community.idera.com/powershell/powertips/b/tips/posts/using-nested-hash-tables)-->
