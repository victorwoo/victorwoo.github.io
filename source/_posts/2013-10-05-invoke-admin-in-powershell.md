---
layout: post
title: "在PowerShell中以管理员身份运行程序"
date: 2013-10-05 00:00:00
description: Invoke-Admin in PowerShell
categories: powershell
tags:
- powershell
- script
- uac
- cmdlet
---
对于已知的需要以管理员身份运行的命令，我们可以通过这个 `Invoke-Admin` 函数运行。这个函数确保以管理员身份运行一个程序。如果不是以管理员身份运行，则将弹出 UAC 对话框。

	function Invoke-Admin() {
	    param ( [string]$program = $(throw "Please specify a program" ),
	            [string]$argumentString = "",
	            [switch]$waitForExit )

	    $psi = new-object "Diagnostics.ProcessStartInfo"
	    $psi.FileName = $program
	    $psi.Arguments = $argumentString
	    $psi.Verb = "runas"
	    $proc = [Diagnostics.Process]::Start($psi)
	    if ( $waitForExit ) {
	        $proc.WaitForExit();
	    }
	}

来源：[Showing the UAC prompt in PowerShell if the action requires elevation][1]

[1]: http://stackoverflow.com/questions/1566969/showing-the-uac-prompt-in-powershell-if-the-action-requires-elevation "Showing the UAC prompt in PowerShell if the action requires elevation"
