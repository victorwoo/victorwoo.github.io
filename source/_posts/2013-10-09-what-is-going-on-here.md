---
layout: post
title: "PowerShell 技能连载 - 发生了什么？"
date: 2013-10-09 00:00:00
description: PowerTip of the Day - What Is Going On Here?
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
经常地，您需要用 PowerShell 来获取数据，并且您需要提取信息的一部分并且把它们用于报表。类似如下：

	$serial = Get-WmiObject -Class Win32_OperatingSystem |
	  Select-Object -Property SerialNumber

	"Serial Number is $serial"

但是上述代码产生的结果如下：

	Serial Number is @{SerialNumber=00261-30000-00000-AA825}

当您查看 $serial 的值，它看起来似乎很正常：

	PS> $serial

	SerialNumber
	------------
	00261-30000-00000-AA825

但问题出在列头（译者注：我们只需要 SerialNumber 的值，而不是需要一个包含 SerialNumber 属性的临时对象）。您可以用 `Select-Object` 只选出一列，用 `-ExpandProperty` 而不是 `-Property` 就可以消除列头：

	$serial = Get-WmiObject -Class Win32_OperatingSystem |
	  Select-Object -ExpandProperty SerialNumber

	"Serial Number is $serial"

现在，一切正常了：

	Serial Number is 00261-30000-00000-AA825


<!--本文国际来源：[What Is Going On Here?](http://community.idera.com/powershell/powertips/b/tips/posts/what-is-going-on-here)-->
