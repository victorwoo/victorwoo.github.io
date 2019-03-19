---
layout: post
title: "PowerShell 技能连载 - 通过CSV创建对象"
date: 2013-10-01 00:00:00
description: PowerTip of the Day - Creating Objects with CSV
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
有多种方法可以创建自定义对象。以下是一种创新的办法，在很多种场景中都很有效：创建一个逗号分隔，每行表示一个值的列表文本，然后用 `ConvertFrom-Csv` 来创建对象：

	for($x=0; $x -lt 20; $x++)
	{
	    ($x,(Get-Random),(Get-Date) -join ',') | ConvertFrom-Csv -Header ID, RandomNumber, Date
	}

不过，这种做法效率并不是很高。还有三种其它方法可以用来创建对象。分别用 `Measure-Command` 测量创建 2000 个对象所消耗的时间：

	Measure-Command {
		for($x=0; $x -lt 2000; $x++)
		{
		    ($x,(Get-Random),(Get-Date) -join ',') | ConvertFrom-Csv -Header ID, RandomNumber, Date
		}
	}

	Measure-Command {
		for($x=0; $x -lt 2000; $x++)
		{
		    $obj = 1 | Select-Object -Property ID, RandomNumber, Date
		    $obj.ID = $x
		    $obj.RandomNumber = Get-Random
		    $obj.Date = Get-Date
		    $obj
		}
	}

	Measure-Command {
		for($x=0; $x -lt 2000; $x++)
		{
		    [PSObject]@{
		        ID = $x
		        RandomNumber = Get-Random
		        Date = Get-Date
		    }
		}
	}

	Measure-Command {
		for($x=0; $x -lt 2000; $x++)
		{
		    [Ordered]@{
		        ID = $x
		        RandomNumber = Get-Random
		        Date = Get-Date
		    }
		}
	}


如结果所示，最后两种方法的效率是 CSV 方法的大约三倍。在我们的测试系统上，所有的测试都在一秒之内完成，所以现实环境中影响并不大。

请挑选一个您自己最喜欢的方式——不过请注意最后一个例子需要 PowerShell 3.0 或更高的版本。

<!--本文国际来源：[Creating Objects with CSV](http://community.idera.com/powershell/powertips/b/tips/posts/creating-objects-with-csv)-->
