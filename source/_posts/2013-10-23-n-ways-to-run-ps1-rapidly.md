layout: post
title: "快速运行 .ps1 脚本的 N 种方法"
date: 2013-10-23 00:00:00
description: N Ways to Run .ps1 Rapidly
categories: powershell
tags:
- powershell
- command
- cmd
- registry
- script
- geek
---
由于安全的原因，微软禁止以双击的方式执行 PowerShell 的 .ps1 脚本。但如果我们一味地追求效率，而暂时“无视”其安全性的话，要怎样快速地执行 .ps1 脚本呢？以下是 QQ 群里讨论的一些方案：

为每个 .ps1 配一个 .cmd 批处理文件
===============================
这种方法适用于可能需要将 PowerShell 脚本发送给朋友执行，而朋友可能只是初学者或普通用户的场景，并且该脚本不会修改注册表。具体做法是：将以下代码保存为一个 .cmd 文件，放在 .ps1 的同一个目录下。**注意主文件名必须和 .ps1 的主文件名一致**。

	@set Path=%Path%;%SystemRoot%\system32\WindowsPowerShell\v1.0\ & powershell -ExecutionPolicy Unrestricted -NoExit -NoProfile %~dpn0.ps1

例如，您希望朋友执行 My-Script.ps1，那么您只需要将以上代码保存为 My-Script.cmd，放在同一个目录之下发给您的朋友即可。

这种方法还有个小小的好处是，不需要为不同的 .ps1 而修改 .cmd 的内容。

用批处理文件做一个简单的菜单，列出 .ps1 文件
=======================================
<!--more-->
该方法由 @PS 网友提供。优点在于可以为多个 .ps1 脚本配一个 .cmd 批处理。执行 .cmd 以后，将显示一个简易的字符界面选择菜单。可以根据用户的选择执行相应的 .ps1 脚本。以下是代码：

	@echo off
	setlocal enabledelayedexpansion
	for  %%i in (*.ps1) do (
	     set /a num+=1
	     set .!num!=%%i
	     echo !num!. %%i
	)
	set/p n=这里输入序列：
	echo !.%n%!
	set Path=%Path%;%SystemRoot%\system32\WindowsPowerShell\v1.0\ & powershell -ExecutionPolicy Unrestricted -NoProfile .\!.%n%!
	pause

用命令行修改 PowerShell 文件的打开方式
===================================
该方法由 @史瑞克 网友提供，只需要在命令行中执行一次以下代码，以后即可双击运行 .ps1 脚本：

	ftype Microsoft.PowerShellScript.1="%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" ".\%1"

用这种方法可以设置打开方式和默认打开方式，需要管理员权限。恢复方法：

	ftype Microsoft.PowerShellScript.1="%SystemRoot%\system32\notepad.exe" "%1"

用 PowerShell 脚本修改 PowerShell 文件的打开方式
=============================================
该方法由 StackOverflow 上的 @JPBlanc 网友提供。只需要在 PowerShell 中执行一次以下代码，以后即可双击运行 .ps1 脚本。优点是可以开可以关。原文是法文，已由 @Andy Arismendi 网友翻译为英文。

	<#  
	.SYNOPSIS  
	    Change the registry key in order that double-clicking on a file with .PS1 extension
	    start its execution with PowerShell.
	.DESCRIPTION
	    This operation bring (partly) .PS1 files to the level of .VBS as far as execution
	    through Explorer.exe is concern.
	    This operation is not advised by Microsoft.
	.NOTES  
	    File Name   : ModifyExplorer.ps1  
	    Author      : J.P. Blanc - jean-paul_blanc@silogix-fr.com
	    Prerequisite: PowerShell V2 on Vista and later versions.
	    Copyright 2010 - Jean Paul Blanc/Silogix    
	.LINK  
	    Script posted on:  
	    http://www.silogix.fr  
	.EXAMPLE  
	    PS C:\silogix> Set-PowAsDefault -On
	    Call Powershell for .PS1 files.
	    Done !
	.EXAMPLE    
	    PS C:\silogix> Set-PowAsDefault
	    Tries to go back  
	    Done !
	#>  
	function Set-PowAsDefault
	{
	  [CmdletBinding()]
	  Param
	  (
	    [Parameter(mandatory=$false,ValueFromPipeline=$false)]
	    [Alias("Active")]
	    [switch]
	    [bool]$On
	  )
	
	  begin 
	  {
	    if ($On.IsPresent)
	    {
	      Write-Host "Call Powershell for .PS1 files."
	    }
	    else
	    {
	      Write-Host "Try to go back."
	    }
	  }
	
	  Process 
	  {
	    # Text Menu
	    [string]$TexteMenu = "Go inside PowerShell"
	
	    # Text of the program to create
	    [string] $TexteCommande = "%systemroot%\system32\WindowsPowerShell\v1.0\powershell.exe -Command ""&'%1'"""
	
	    # Key to create
	    [String] $clefAModifier = "HKLM:\SOFTWARE\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command"
	
	    try
	    {
	      $oldCmdKey = $null
	      $oldCmdKey = Get-Item $clefAModifier -ErrorAction SilentlyContinue
	      $oldCmdValue = $oldCmdKey.getvalue("")
	
	      if ($oldCmdValue -ne $null)
	      {
	        if ($On.IsPresent)
	        {
	          $slxOldValue = $null
	          $slxOldValue = Get-ItemProperty $clefAModifier -Name "slxOldValue" -ErrorAction SilentlyContinue
	          if ($slxOldValue -eq $null)
	          {
	            New-ItemProperty $clefAModifier -Name "slxOldValue" -Value $oldCmdValue  -PropertyType "String" | Out-Null
	            New-ItemProperty $clefAModifier -Name "(default)" -Value $TexteCommande  -PropertyType "ExpandString" | Out-Null
	            Write-Host "Done !"
	          }
	          else
	          {
	            Write-Host "Already done !"          
	          }
	
	        }
	        else
	        {
	          $slxOldValue = $null
	          $slxOldValue = Get-ItemProperty $clefAModifier -Name "slxOldValue" -ErrorAction SilentlyContinue 
	          if ($slxOldValue -ne $null)
	          {
	            New-ItemProperty $clefAModifier -Name "(default)" -Value $slxOldValue."slxOldValue"  -PropertyType "String" | Out-Null
	            Remove-ItemProperty $clefAModifier -Name "slxOldValue" 
	            Write-Host "Done !"
	          }
	          else
	          {
	            Write-Host "No former value !"          
	          }
	        }
	      }
	    }
	    catch
	    {
	      $_.exception.message
	    }
	  }
	  end {}
	}

使用方法很简单，`Set-PowAsDefault -On`为打开，`Set-PowAsDefault`为关闭。需要管理员权限。

以上是目前搜集的几种方法，希望对您有用。您可以在[这里](/download/2013-10-23-n-ways-to-run-ps1-rapidly.zip)下载以上所有脚本的例子。
