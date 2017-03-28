layout: post
title: "获取最常用的 PowerShell Cmdlet 别名"
date: 2014-01-10 00:00:00
description: Get Most Used Alias of PowerShell Cmdlet
categories: powershell
tags: powershell
---
我们可以对 Get-Alias 的结果进行分组和排序，看看常用的别名有哪些。

	gal | group Definition | sort Count -Descending

执行结果：

	Count Name                      Group
	----- ----                      -----
	    6 Remove-Item               {del, erase, rd, ri...}
	    3 Move-Item                 {mi, move, mv}
	    3 Invoke-WebRequest         {curl, iwr, wget}
	    3 Copy-Item                 {copy, cp, cpi}
	    3 Get-ChildItem             {dir, gci, ls}
	    3 Set-Location              {cd, chdir, sl}
	    3 Get-Content               {cat, gc, type}
	    3 Get-History               {ghy, h, history}
	    2 Start-Process             {saps, start}
	    2 ForEach-Object            { %, foreach}
	    2 Get-Location              {gl, pwd}
	    2 Invoke-History            {ihy, r}
	    2 Rename-Item               {ren, rni}
	    2 Get-Process               {gps, ps}
	    2 Write-Output              {echo, write}
	    2 Set-Variable              {set, sv}
	    2 Clear-Host                {clear, cls}
	    2 Stop-Process              {kill, spps}
	    2 New-PSDrive               {mount, ndr}
	    2 Compare-Object            {compare, diff}
	    2 Where-Object              {?, where}
	    1 Receive-Job               {rcjb}
	    1 Receive-PSSession         {rcsn}
	    1 Measure-Object            {measure}
	    1 Remove-PSBreakpoint       {rbp}
	    1 Remove-PSDrive            {rdr}
	    1 mkdir                     {md}
	...

还可以用如下命令查看只有 1 个字母的别名（肯定最常用了）：

	gal | where { $_.Name.Length -eq 1 }

	CommandType     Name                                               ModuleName
	-----------     ----                                               ----------
	Alias           % -> ForEach-Object
	Alias           ? -> Where-Object
	Alias           h -> Get-History
	Alias           r -> Invoke-History
